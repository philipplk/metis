classdef GGL_theta_mod < Integrator
    % One-stage-theta-method (1) for GGL-like constrained DAE
    %
    % - based on constraint on position and velocity level
    %   (GGL-stabilisation)
    %
    % - independent momentum variables (Hamilton Potryagin approach)
    %
    % - derived from one-stage thetat method (constraints have been modified)
    %
    %
    % Author: Philipp Kinon
    % Date  : 28.01.2021

    methods

        function self = GGL_theta_mod(this_simulation, this_system)
            self.DT = this_simulation.DT;
            self.T_0 = this_simulation.T_0;
            self.T_END = this_simulation.T_END;
            self.t = this_simulation.T_0:this_simulation.DT:this_simulation.T_END;
            self.NT = size(self.t, 2) - 1;
            self.nVARS = 2 * this_system.nDOF + 2 * this_system.mCONSTRAINTS;
            self.INDI_VELO = false;
            self.LM0 = zeros(2*this_system.mCONSTRAINTS, 1);
            self.hasPARA = true;
            self.PARA = this_simulation.INT_PARA(1);
            self.NAME = 'GGL-theta';
            self.has_enhanced_constraint_force = true;
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

            %% Unknows which will be iterated
            qn1 = zn1(1:n);
            pn1 = zn1(n+1:2*n);
            lambdan = zn1(2*n+1:2*n+m);
            gamman = zn1(2*n+m+1:end);
            G_n1 = this_system.constraint_gradient(qn1);
            g_n1 = this_system.constraint(qn1);

            %% Known quantities from last time-step
            qn = zn(1:n);
            pn = zn(n+1:2*n);

            %% Theta-evaluated Quantities
            theta = self.PARA(1);
            q_nt = (1 - theta) * qn + theta * qn1;
            p_n1mt = theta * pn + (1 - theta) * pn1;
            DV_nt = this_system.internal_potential_gradient(q_nt) + this_system.external_potential_gradient(q_nt);
            G_nt = this_system.constraint_gradient(q_nt);
            D2V_nt = this_system.internal_potential_hessian(q_nt) + this_system.external_potential_hessian(q_nt);

            % Hessian of constraints are multiplied by LMs for each
            % Constraint (avoid 3rd order tensor)
            t_nt_gam = zeros(n);
            t_nt_lam = zeros(n);
            T_n1 = zeros(m, n);
            T_nt = zeros(m, n);
            for j = 1:m
                tmp_1 = this_system.constraint_hessian(qn1, j);
                tmp_nt = this_system.constraint_hessian(q_nt, j);
                t_nt_gam = t_nt_gam + this_system.constraint_hessian(q_nt, j) * gamman(j);
                t_nt_lam = t_nt_lam + this_system.constraint_hessian(q_nt, j) * lambdan(j);
                for k = 1:n
                    T_n1(j, k) = tmp_1(:, k)' * IM * pn1;
                    T_nt(j, k) = tmp_nt(:, k)' * IM * p_n1mt;
                end
            end

            %% Residual vector
            resi = [qn1 - qn - h * IM * p_n1mt - h * IM * G_nt' * gamman; pn1 - pn + h * DV_nt + h * G_nt' * lambdan + h * t_nt_gam * IM * p_n1mt; g_n1; G_n1 * IM * pn1];

            %% Tangent matrix
            tang = [eye(n) - h * IM * theta * t_nt_gam, -h * IM * (1 - theta), zeros(n, m), -h * IM * G_nt'; h * D2V_nt * theta + h * theta * t_nt_lam, eye(n) + h * t_nt_gam * IM * (1 - theta), h * G_nt', h * T_nt'; G_n1, zeros(n, m)', zeros(m), zeros(m); T_n1, G_n1 * IM, zeros(m), zeros(m)];

        end

    end

end
