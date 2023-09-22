%% Class: PendulumMinCoord
%
% Spherical pendulum in minimal coordinates (two angles).
%

classdef PendulumMinCoord < System

    properties

    end

    methods

        function self = PendulumMinCoord(CONFIG)

            self.mCONSTRAINTS = 0;
            self.nBODIES = 1;
            self.DIM = CONFIG.DIM;
            self.MASS = CONFIG.MASS;
            self.nDOF = 2;
            self.mMixedQuantities = 0;
            self.MASS_MAT = [];
            self.EXT_ACC = CONFIG.EXT_ACC;

           % Resting lengths of the springs
            self.GEOM(1) = 1; %length of the pendulum l

            self.nPotentialInvariants = 0;

            self.DISS_MAT = zeros(2,2);

            self.isCyclicCoordinate = [false;true];


        end
        
        function M = get_mass_matrix(self, q)
            
            theta = q(1);
            m =  self.MASS;
            l = self.GEOM(1);
            M = diag([m*l^2, m*l^2*(sin(theta))^2]);

        end

                function M = get_mass_matrix_cyclic(self, x)
            
            theta = x(1);
            m =  self.MASS;
            l = self.GEOM(1);
            M = diag([m*l^2, m*l^2*(sin(theta))^2]);

        end

        function r = get_cartesian_coordinates(self, q)

            theta = q(1);
            phi = q(2);
            l = self.GEOM(1);
            r = [l*sin(theta)*cos(phi); l*sin(theta)*sin(phi); -l*cos(theta)];
            
        end

        function r_dot = get_cartesian_velocities(self, q, v)
            
            theta = q(1);
            phi = q(2);
            v_theta = v(1);
            v_phi = v(2);
            l = self.GEOM(1);
            r_dot = [l*cos(theta)*cos(phi)*v_theta - l*sin(theta)*sin(phi)*v_phi; l*cos(theta)*sin(phi)*v_theta + l*sin(theta)*cos(phi)*v_phi; l*sin(theta)*v_theta];
            
        end

        function r_dot = get_cartesian_velocities_from_momentum(self, q, p)
            
            theta = q(1);
            phi = q(2);
            l = self.GEOM(1);
            m = self.MASS;
            p_theta = p(1);
            v_theta = 1/(m*l^2)*p_theta;
            p_phi = p(2);
            v_phi = 1/(m*l^2*sin(theta)^2)*p_phi;
            r_dot = [l*cos(theta)*cos(phi)*v_theta - l*sin(theta)*sin(phi)*v_phi; 
                     l*cos(theta)*sin(phi)*v_theta + l*sin(theta)*cos(phi)*v_phi; 
                     l*sin(theta)*v_theta];
            
        end

        function Dq_T = kinetic_energy_gradient_from_velocity(self, q, v)
            
            theta = q(1);
            v_phi = v(2);
            m =  self.MASS;
            l = self.GEOM(1);

            Dq_T = [m*l^2*sin(theta)*cos(theta)*v_phi^2; 0];

        end

        function Dq_T = kinetic_energy_gradient_from_velocity_cyclic(self, x, v)
            
            theta = x(1);
            v_phi = v(2);
            m =  self.MASS;
            l = self.GEOM(1);

            Dq_T = [m*l^2*sin(theta)*cos(theta)*v_phi^2];

        end

        function Dq_T = kinetic_energy_gradient_from_momentum(self, q, p)
            
            theta = q(1);
            p_phi = p(2);
            m =  self.MASS;
            l = self.GEOM(1);

            Dq_T = [-cos(theta)/(m*l^2*(sin(theta))^3)*p_phi^2; 0];

        end

        function L = get_cartesian_angular_momentum_from_momentum(~, q, p)
            
            theta = q(1);
            phi = q(2);
            p_theta = p(1);
            p_phi = p(2);

            L = [sin(phi)*p_theta + cos(theta)/sin(theta)*cos(phi)*p_phi;
                 -p_theta*cos(phi)+ cos(theta)/sin(theta)*sin(phi)*p_phi;
                 p_phi];

        end

        %% Potential functions

        function V_ext = external_potential(self, q)
            % External potential
            theta = q(1);
            m =  self.MASS;
            g =  self.EXT_ACC;
            l = self.GEOM(1);
            V_ext = -m*g*l*cos(theta);

        end

        function V_ext = external_potential_cyclic(self, x)
            % External potential
            theta = x(1);
            m =  self.MASS;
            g =  self.EXT_ACC;
            l = self.GEOM(1);
            V_ext = -m*g*l*cos(theta);

        end

        function DV_ext = external_potential_gradient(self, q)
            theta = q(1);
            m =  self.MASS;
            g =  self.EXT_ACC;
            l = self.GEOM(1);
            DV_ext = [m*g*l*sin(theta); 0];
        end

        function DV_ext = external_potential_gradient_cyclic(self, x)
            theta = x(1);
            m =  self.MASS;
            g =  self.EXT_ACC;
            l = self.GEOM(1);
            DV_ext = [m*g*l*sin(theta)];
        end

        function D2V_ext = external_potential_hessian(self, q)
            theta = q(1);
            m =  self.MASS;
            g =  self.EXT_ACC;
            l = self.GEOM(1);
            D2V_ext = [m*g*l*cos(theta), 0; 0, 0];

        end

        function V_int = internal_potential(~, ~)
            V_int = 0;
        end

        function DV_int = internal_potential_gradient(~, q)
            DV_int = zeros(size(q));
        end

        function D2V_int = internal_potential_hessian(~, q)
            D2V_int = zeros(size(q, 1));
        end


        %% Constraint on position level

        function g = constraint(~, ~)
           
            g=NaN;

        end

        function Dg = constraint_gradient(~, ~)
           
            Dg=NaN;

        end

        function D2g = constraint_hessian(~, ~, ~)

             D2g=NaN;

        end

        %% Invariant formulations
        %  e.g. for EMS

        % Invariant of the internal potential
        function pi = potential_invariant(~, q, i)

            
                error('system has no invariants for the potential.');
     

        end

            % gradient of potential invariants w.r.t. q
        function DpiDq = potential_invariant_gradient(~, q, i)
            
                error('system has no invariants for the potential.');

        end

        % gradient of potential invariants w.r.t. q
        function D2piDq = potential_invariant_hessian(~, ~, i)

            
                error('system has no invariants for the potential.');
            
        end

        % internal potential computed with the invariant
        function Vs = potential_from_invariant(self, pi, i)
            error('system has no invariants for the potential.');
        end

        % gradient of internal potential w.r.t. the invariant
        function DVsDpi = potential_gradient_from_invariant(self, pi, i)
            error('system has no invariants for the potential.');
        end

        % invariant of the velocity invariant
        function pi2 = vConstraint_invariant(~, ~, ~, ~)

           error('not available.')
        
        end

        % gradient of the invariant of the velocity constraint w.r.t. q
        function Dpi2Dq = vConstraint_invariant_gradient_q(~, ~, ~, ~)

           error('not available.')

    end

    % gradient of the invariant of the velocity constraint w.r.t. p
    function Dpi2Dp = vConstraint_invariant_gradient_p(~, ~, ~, ~)

         error('not available.')

     end

  function D2piDqDp = vConstraint_invariant_hessian_qp(~, ~, ~, ~)

        error('not available.')
  end

% velocity constraint computed with its invariant
    function gv = Vconstraint_from_invariant(~, ~, ~, ~)

      error('not available.')

    end

    function DgvDpi = Vconstraint_gradient_from_invariant(~, ~, ~, ~)

       error('not available.')
    end

    % invariant of the position constraint
    function zeta = constraint_invariant(~, ~, ~)

       error('not available.')
    end

    % gradient of the invariant of the position constraint w.r.t. q
    function DzetaDq = constraint_invariant_gradient(~, ~, ~)

        error('not available.')
    end

    % gradient of the invariant of the position constraint w.r.t. q
    function D2zetaDq2 = constraint_invariant_hessian(~, ~, ~)

      error('not available.')
    end

    % position constrained computed with its invariant
      function gs = constraint_from_invariant(~, ~, ~)

            error('not available.')
      end

    % gradient of position constrained w.r.t. its invariant
    function gs = constraint_gradient_from_invariant(~, ~, ~)

        error('not available.')
    end

     function analyzed_quantity = hconvergence_set(~, this_simulation)

        if strcmp(this_simulation.CONV_QUANTITY,'q')
            analyzed_quantity = this_simulation.z(end, 2); %position of 4th particle
        elseif strcmp(this_simulation.CONV_QUANTITY,'p')
            analyzed_quantity = this_simulation.z(end, 4); %momentum of 4th particle
        elseif strcmp(this_simulation.CONV_QUANTITY,'lambda')
            error('not available.')
        else
            error('quantity not yet implemented for convergence analysis.')
        end

    end


    function reference_solution = hconvergence_reference(~, ~, analyzed_quantity)

        reference_solution = analyzed_quantity(:, end, end); %position
      
    end

        %% Animation method
            function give_animation(self, fig, this_simulation)


                DIM = self.DIM;
                q1 = this_simulation.z(:, 1:DIM);
                q2 = this_simulation.z(:, DIM+1:2*DIM);
                q3 = this_simulation.z(:, 2*DIM+1:3*DIM);
                q4 = this_simulation.z(:, 3*DIM+1:4*DIM);
                xmin = min([min(q1(:, 1)), min(q2(:, 1)), min(q3(:, 1)), min(q4(:, 1))]);
                ymin = min([min(q1(:, 2)), min(q2(:, 2)), min(q3(:, 2)), min(q4(:, 2))]);
                zmin = min([min(q1(:, 3)), min(q2(:, 3)), min(q3(:, 3)), min(q4(:, 3))]);
                xmax = max([max(q1(:, 1)), max(q2(:, 1)), max(q3(:, 1)), max(q4(:, 1))]);
                ymax = max([max(q1(:, 2)), max(q2(:, 2)), max(q3(:, 2)), max(q4(:, 2))]);
                zmax = max([max(q1(:, 3)), max(q2(:, 3)), max(q3(:, 3)), max(q4(:, 3))]);
                NT = size(q1, 1);

                axis equal
                %axis([xmin, xmax, ymin, ymax, zmin, zmax]);
                %xlabel('x');
                %ylabel('y');
                %zlabel('z');
                %grid on;
                axis off

                xa1 = q1(1, 1);
                xa2 = q2(1, 1);
                xa3 = q3(1, 1);
                xa4 = q4(1, 1);
                ya1 = q1(1, 2);
                ya2 = q2(1, 2);
                ya3 = q3(1, 2);
                ya4 = q4(1, 2);

                if DIM == 3
                    za1 = q1(1, 3);
                    za2 = q2(1, 3);
                    za3 = q3(1, 3);
                    za4 = q4(1, 3);
                else
                    za1 = 0;
                    za2 = 0;
                    za3 = 0;
                    za4 = 0;
                end

                for j = 1:NT

                    cla(fig);
                    hold on

                    %% Current position
                    x1 = q1(j, 1);
                    x2 = q2(j, 1);
                    x3 = q3(j, 1);
                    x4 = q4(j, 1);

                    y1 = q1(j, 2);
                    y2 = q2(j, 2);
                    y3 = q3(j, 2);
                    y4 = q4(j, 2);

                    if DIM == 3
                        z1 = q1(j, 3);
                        z2 = q2(j, 3);
                        z3 = q3(j, 3);
                        z4 = q4(j, 3);
                    else
                        z1 = 0;
                        z2 = 0;
                        z3 = 0;
                        z4 = 0;
                    end

                    %% Reference sphere
                    %                     plot3(xa1, ya1, za1, 'mo', 'MarkerSize', 10, 'MarkerEdgeColor', [0.75, 0, 0], 'MarkerFaceColor', [0.75, 0, 0]);
                    %                     hold on
                    %                     plot3(xa2, ya2, za2, 'mo', 'MarkerSize', 10, 'MarkerEdgeColor', [0.75, 0, 0], 'MarkerFaceColor', [0.75, 0, 0]);
                    %                     hold on
                    %                     plot3(xa3, ya3, za3, 'mo', 'MarkerSize', 10, 'MarkerEdgeColor', [0.75, 0, 0], 'MarkerFaceColor', [0.75, 0, 0]);
                    %                     hold on
                    %                     plot3(xa4, ya4, za4, 'mo', 'MarkerSize', 10, 'MarkerEdgeColor', [0.75, 0, 0], 'MarkerFaceColor', [0.75, 0, 0]);
                    %                     hold on

                    %% Reference constraint
                    %                     xx3 = [xa1; xa2];
                    %                     yy3 = [ya1; ya2];
                    %                     zz3 = [za1; za2];
                    %                     xxx3 = [xa3; xa4];
                    %                     yyy3 = [ya3; ya4];
                    %                     zzz3 = [za3; za4];
                    %                     plot3(xx3, yy3, zz3, 'k', 'LineWidth', 2);
                    %                     hold on
                    %                     plot3(xxx3, yyy3, zzz3, 'k', 'LineWidth', 2);

                    %% Reference position of the springs
                    %                     xx_3 = [xa1; xa3];
                    %                     yy_3 = [ya1; ya3];
                    %                     zz_3 = [za1; za3];
                    %                     xxxx_3 = [xa2; xa4];
                    %                     yyyy_3 = [ya2; ya4];
                    %                     zzzz_3 = [za2; za4];
                    %
                    %                     tmp  = gfx_springelement([xa1,ya1,za1],[xa3,ya3,za3],1,0.1,5);
                    %                     tmp2 = gfx_springelement([xa2,ya2,za2],[xa4,ya4,za4],1,0.1,5);
                    %
                    %                     %plot3(xx_3, yy_3, zz_3, 'k--');
                    %                     plot3(tmp(1,:),tmp(2,:),tmp(3,:),'LineWidth',1.5);
                    %                     hold on
                    %                     %plot3(xxxx_3, yyyy_3, zzzz_3, 'k--');
                    %                     plot3(tmp2(1,:),tmp2(2,:),tmp2(3,:),'LineWidth',1.5);

                    %% current position of the mass
                    %hold on
                    %if DIM == 3
                    %    plot3(q1(1:j, 1), q1(1:j, 2), q1(1:j, 3), 'k');
                    %    plot3(q2(1:j, 1), q2(1:j, 2), q2(1:j, 3), 'k');
                    %    plot3(q3(1:j, 1), q3(1:j, 2), q3(1:j, 3), 'k');
                    %    plot3(q4(1:j, 1), q4(1:j, 2), q4(1:j, 3), 'k');
                    %else
                    %    plot3(q1(1:j, 1), q1(1:j, 2), zeros(j, 1), 'k');
                    %    plot3(q2(1:j, 1), q2(1:j, 2), zeros(j, 1), 'k');
                    %    plot3(q3(1:j, 1), q3(1:j, 2), zeros(j, 1), 'k');
                    %    plot3(q4(1:j, 1), q4(1:j, 2), zeros(j, 1), 'k');
                    %end
                    plot3(x1, y1, z1, 'mo', 'MarkerSize', 40, 'MarkerEdgeColor', '#4477AA', 'MarkerFaceColor', '#4477AA');
                    plot3(x2, y2, z2, 'mo', 'MarkerSize', 40, 'MarkerEdgeColor', '#4477AA', 'MarkerFaceColor', '#4477AA');
                    plot3(x3, y3, z3, 'mo', 'MarkerSize', 40, 'MarkerEdgeColor', '#4477AA', 'MarkerFaceColor', '#4477AA');
                    plot3(x4, y4, z4, 'mo', 'MarkerSize', 40, 'MarkerEdgeColor', '#4477AA', 'MarkerFaceColor', '#4477AA');

                    %grid on

                    %% current position of the constraint
                    x_3 = [x1; x2];
                    y_3 = [y1; y2];
                    z_3 = [z1; z2];
                    xxx3 = [x3; x4];
                    yyy3 = [y3; y4];
                    zzz3 = [z3; z4];
                    plot3(x_3, y_3, z_3, 'k', 'linewidth', 2);
                    plot3(xxx3, yyy3, zzz3, 'k', 'linewidth', 2);

                    %% Current position of the springs
                    xx3 = [x1; x3];
                    yy3 = [y1; y3];
                    zz3 = [z1; z3];
                    xxxx3 = [x2; x4];
                    yyyy3 = [y2; y4];
                    zzzz3 = [z2; z4];

                    tmp3 = gfx_springelement([x1, y1, z1], [x3, y3, z3], 1, 0.05, 7);
                    tmp4 = gfx_springelement([x2, y2, z2], [x4, y4, z4], 1, 0.05, 7);

                    %plot3(xx3, yy3, zz3, 'k--');
                    plot3(tmp3(1, :), tmp3(2, :), tmp3(3, :), 'k', 'LineWidth', 1.5);
                    hold on
                    plot3(tmp4(1, :), tmp4(2, :), tmp4(3, :), 'k', 'LineWidth', 1.5);
                    %plot3(xxxx3, yyyy3, zzzz3, 'k--');


                    if DIM == 2
                        view(0, 90)
                    else
                        view(136, 23)
                    end

                    drawnow

                    print(gcf, strcat('snapshot_', num2str(j)), '-dpng')

                end

        end

    end

end
