classdef GGL_VI_theta_A < Integrator
%% Runge-Kutta typed scheme for GGL-like constrained DAE
%
% - based on constraint on position and velocity level 
%   (GGL-stabilisation)
%
% - independent momentum variables (Hamilton Potryagin approach)
%
% - derived from variational principle
%
% - symplectic method
%
% Author: Philipp Kinon
% Date  : 28.01.2021

    methods
        
        function self = GGL_VI_theta_A(this_simulation,this_problem)
            self.DT    = this_simulation.DT;
            self.T_0   = this_simulation.T_0;
            self.T_END = this_simulation.T_END;
            self.t     = this_simulation.T_0:this_simulation.DT:this_simulation.T_END;
            self.NT    = size(self.t, 2) - 1;
            self.nVARS = 3*this_problem.nDOF+2*this_problem.mCONSTRAINTS;
            self.LM0   = zeros(2*this_problem.mCONSTRAINTS,1);
            self.hasPARA = true;
            self.PARA  = this_simulation.INT_PARA(1);
            self.NAME  = 'GGL-VI-theta-A';
        end
        
        function z0 = set_initial_condition(self,this_simulation,this_system)
            
           z0 = [this_simulation.Q_0', (this_system.MASS_MAT * this_simulation.V_0)', this_simulation.V_0' , self.LM0'];
            
        end
            
        function [resi,tang] = compute_resi_tang(self,zn1,zn,this_problem)
            
            %% Abbreviations
            M  = this_problem.MASS_MAT;
            IM = M\eye(size(M));
            h  = self.DT;
            n  = this_problem.nDOF;
            m  = this_problem.mCONSTRAINTS;
            
            %% Unknows which will be iterated
            qn1     = zn1(1:n);
            pn1     = zn1(n+1:2*n);
            vn1     = zn1(2*n+1:3*n);
            lambdan = zn1(3*n+1:3*n+m);
            gamman  = zn1(3*n+m+1:end);
            
            %% Known quantities from last time-step
            qn     = zn(1:n);
            pn     = zn(n+1:2*n);
            
            %% Quantities at t_n+theta
            theta   = self.PARA(1);
            q_nt    = (1-theta)*qn + theta*qn1;
            p_n1mt  = theta*pn + (1-theta)*pn1;
            g_nt    = this_problem.constraint(q_nt);
            DV_nt   = this_problem.internal_potential_gradient(q_nt) + this_problem.external_potential_gradient(q_nt);
            G_nt    = this_problem.constraint_gradient(q_nt);
            D2V_nt  = this_problem.internal_potential_hessian(q_nt) + this_problem.external_potential_hessian(q_nt);
            
            % Hessian of constraints are multiplied by LMs for each
            % Constraint (avoid 3rd order tensor)
            t_nt_gam = zeros(n);
            t_nt_lam = zeros(n);
            T_n1     = zeros(m,n);
            T_nt     = zeros(m,n);
            for j = 1:m
                tmp_1 = this_problem.constraint_hessian(qn1,j);
                tmp_nt = this_problem.constraint_hessian(q_nt,j);
                t_nt_gam   = t_nt_gam + this_problem.constraint_hessian(q_nt,j)*gamman(j);
                t_nt_lam   = t_nt_lam + this_problem.constraint_hessian(q_nt,j)*lambdan(j);
                for k = 1:n
                    T_n1(j,k) = tmp_1(:,k)'*IM*pn1;
                    T_nt(j,k) = tmp_nt(:,k)'*IM*p_n1mt;
                end
            end
            
            %% Residual vector 
            resi = [qn1 - qn - h*vn1 - h*IM*G_nt'*gamman                  ;
                    pn1 - pn + h*DV_nt + h*G_nt'*lambdan + h*t_nt_gam*vn1;
                    M*vn1 - p_n1mt;
                    g_nt                                              ;
                    G_nt*vn1                                              ];

            %% Tangent matrix
            tang = [];
            %tang = [eye(n) - h*IM*theta*t_nt_gam         -h*IM*(1-theta)               zeros(n,m)      -h*IM*G_nt' ;
            %        h*D2V_nt*theta + h*theta*t_nt_lam    eye(n)+h*t_nt_gam*IM*(1-theta)    h*G_nt'         h*T_nt'     ;
            %        G_nt*theta                           zeros(n,m)'                   zeros(m)        zeros(m)    ;
            %        T_nt*theta                           G_nt*IM*(1-theta)                       zeros(m)        zeros(m)    ];
        end
        
    end

end