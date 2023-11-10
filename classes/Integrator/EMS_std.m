classdef EMS_std < Integrator
    % Energy_Momentum-Integration scheme for standard constrained DAE
    %
    % - based only on constraint on position level
    %
    % - not derived from variational principle
    %
    % - taken from Gonzales 1999, Hamiltonian framework
    %
    % - uses standard gradient for ext. potential and discrete gradient for
    %   internal potential and constraint

    methods

        function self = EMS_std(this_simulation, this_system)
            self.DT = this_simulation.DT;
            self.T_0 = this_simulation.T_0;
            self.T_END = this_simulation.T_END;
            self.t = this_simulation.T_0:this_simulation.DT:this_simulation.T_END;
            self.NT = size(self.t, 2) - 1;
            self.nVARS = 2 * this_system.nDOF + 1 * this_system.mCONSTRAINTS;
            self.INDI_VELO = false;
            self.LM0 = zeros(this_system.mCONSTRAINTS, 1);
            self.hasPARA = false;
            self.NAME = 'EMS-std';
            self.has_enhanced_constraint_force = false;
        end

        function z0 = set_initial_condition(self, this_simulation, this_system)

            z0 = [this_simulation.Q_0', (this_system.MASS_MAT * this_simulation.V_0)', self.LM0'];

        end

        function [resi, tang] = compute_resi_tang(self, zn1, zn, this_system)
            % computes residual tangent
            %
            % :param zn1: input zn1
            % :param zn: input zn
            % :param this_system: input this_system
            % :returns: [ResidualVector, TangentMatrix]

            %% Abbreviations
            M = this_system.MASS_MAT;
            IM = M \ eye(size(M));
            h = self.DT;
            n = this_system.nDOF;
            m = this_system.mCONSTRAINTS;
            p = this_system.nPotentialInvariants;

            %% Unknows which will be iterated
            qn1 = zn1(1:n);
            pn1 = zn1(n+1:2*n);
            lambda_n1 = zn1(2*n+1:2*n+m);
            G_n1 = this_system.constraint_gradient(qn1);
            g_n1 = this_system.constraint(qn1);

            %% Known quantities from last time-step
            qn = zn(1:n);
            pn = zn(n+1:2*n);

            %% MP evaluated quantities
            q_n05 = 0.5 * (qn + qn1);
            p_n05 = 0.5 * (pn + pn1);
            DVext_n05 = this_system.external_potential_gradient(q_n05);
            D2Vext_n05 = this_system.external_potential_hessian(q_n05);
            D2Vint_n05 = this_system.internal_potential_hessian(q_n05);

            %% Discrete gradients
            % for the internal potential
            DG_Vint = zeros(n, 1);
            K21_DG_V = zeros(n, n);
            V_invariants_difference_too_small = false;

            % for every invariant individually
            for i = 1:p
                %compute i-th invariants
                pi_n = this_system.potential_invariant(qn, i);
                pi_n1 = this_system.potential_invariant(qn1, i);
                % derivative of invariant w.r.t. q_n05
                DPiq_n05 = this_system.potential_invariant_gradient(q_n05, i);
                % evaluate internal potential depending on invariants
                Vs_n = this_system.potential_from_invariant(pi_n, i);
                Vs_n1 = this_system.potential_from_invariant(pi_n1, i);

                %for the tangent matrix
                D2PiDq2 = this_system.potential_invariant_hessian(q_n05, i);
                DPiDq_n1 = this_system.potential_invariant_gradient(qn1, i);
                DVsDpi_n1 = this_system.potential_gradient_from_invariant(pi_n1, i);

                % if invariants at n and n1 are equal use the midpoint
                % evaluated gradient instead
                if abs(pi_n1-pi_n) > 1e-09
                    % discrete gradient
                    DG_Vint = DG_Vint + (Vs_n1 - Vs_n) / (pi_n1 - pi_n) * DPiq_n05;
                    K21_DG_V = K21_DG_V + DPiq_n05 * (DVsDpi_n1 * DPiDq_n1 * 1 / (pi_n1 - pi_n) - (Vs_n1 - Vs_n) / (pi_n1 - pi_n)^2 * DPiDq_n1)' + (Vs_n1 - Vs_n) / (pi_n1 - pi_n) * 1 / 2 * D2PiDq2;
                else
                    V_invariants_difference_too_small = true;
                    break
                end

            end

            if V_invariants_difference_too_small
                % else use MP evaluation of gradient
                DG_Vint = this_system.internal_potential_gradient(q_n05);
                K21_DG_V = 1 / 2 * D2Vint_n05;
            end

            % for the gradients of the constraints
            DG_g = zeros(m, n);
            K21_DG_g = zeros(n, n);
            g_invariants_difference_too_small = false;

            % for every invariant individually
            for j = 1:this_system.nConstraintInvariants
                %compute i-th invariants
                zeta_n = this_system.constraint_invariant(qn, j);
                zeta_n1 = this_system.constraint_invariant(qn1, j);

                % evaluate constraints depending on invariants
                gs_n = this_system.constraint_from_invariant(zeta_n, j);
                gs_n1 = this_system.constraint_from_invariant(zeta_n1, j);
                % derivative of invariant w.r.t. q_n05
                DzetaDq_n05 = this_system.constraint_invariant_gradient(q_n05, j);

                % tangent matrix terms
                D2zetaDq2 = this_system.constraint_invariant_hessian(qn1, j);
                DgsDzeta_n1 = this_system.constraint_gradient_from_invariant(qn1, j);
                DzetaDq_n1 = this_system.constraint_invariant_gradient(qn1, j);

                % if invariants at n and n1 are equal use the midpoint
                % evaluated gradient instead
                if abs(zeta_n1-zeta_n) > 1e-9
                    % discrete gradient
                    DG_g(j, :) = (gs_n1 - gs_n) / (zeta_n1 - zeta_n) * DzetaDq_n05';
                    K21_DG_g = K21_DG_g + lambda_n1(j) * (DzetaDq_n05' * (DgsDzeta_n1 * DzetaDq_n1 * 1 / (zeta_n1 - zeta_n) - (gs_n1 - gs_n) / (zeta_n1 - zeta_n)^2 * DzetaDq_n1) + (gs_n1 - gs_n) / (zeta_n1 - zeta_n) * 1 / 2 * D2zetaDq2);
                else
                    g_invariants_difference_too_small = true;
                    break
                end

            end

            if g_invariants_difference_too_small
                % else use MP evaluation of gradient
                G_n05 = this_system.constraint_gradient(q_n05);
                DG_g = G_n05;
                for j = 1:this_system.nConstraintInvariants
                    D2g_Dq_n05 = this_system.constraint_hessian(q_n05, j);
                    K21_DG_g = K21_DG_g + 1 / 2 * lambda_n1(j) * D2g_Dq_n05;
                end
            end

            %% Residual vector
            resi = [qn1 - qn - h * IM * p_n05; pn1 - pn + h * DVext_n05 + h * DG_Vint + h * DG_g' * lambda_n1; g_n1];

            %% Tangent matrix
            %           tang = [];
            tang = [eye(n), -h * 0.5 * IM, zeros(n, m); h * 0.5 * D2Vext_n05 + h * K21_DG_V + h * K21_DG_g, eye(n), h * DG_g'; G_n1, zeros(n, m)', zeros(m)];

        end

    end

end