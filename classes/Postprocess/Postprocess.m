classdef Postprocess

    properties
        
        % Color scheme also for colorblind readers
        color_scheme = {'#EE6677', '#228833', '#4477AA', '#CCBB44',  '#66CCEE', '#AA3377', '#BBBBBB'};
        
    end
    
    
    methods

        function self = Postprocess()
            % Function to initialise the postprocessing
            
            set(0, 'defaultfigureposition', [850, 450, 1200, 600])
            
        end

        function animation(~, this_problem, this_simulation)
            % Function which displays an animation of the trajectory if
            % desired by user
            
            if this_simulation.shouldAnimate == true
                
                fig = figure();
                this_problem.give_animation(fig,this_simulation);
                title(strcat(this_simulation.INTEGRATOR, ': Trajectory'))
                current_fig = gcf;
                current_fig.Name = 'final_conf';
                
            end

        end

        function this_simulation = compute(~, this_problem,this_simulation)
            % Function which computes energetic quantities, ang. Mom. , ...
            % as functions of time for a given q and p-vector
            
            nDOF = this_problem.nDOF;
            m    = this_problem.mCONSTRAINTS;
            DIM  = this_problem.DIM;
            d    = nDOF/DIM;
            
            NT   = int32(this_simulation.T_END/this_simulation.DT) +1;
            M    = this_problem.MASS_MAT;
            IM   = M\eye(size(M));
            
            q    = this_simulation.z(:, 1:nDOF);
            p    = this_simulation.z(:, nDOF+1:2*nDOF);
            v    = zeros(NT,nDOF);
            if this_simulation.INDI_VELO == true
                v = this_simulation.z(:,2*nDOF+1:3*nDOF);
            else
                for j=1:NT
                    v(j,:) = (IM*p(j,:)')';
                end
               
            end     

            T = zeros(NT, 1);
            V = zeros(NT, 1);
            H = zeros(NT, 1);
            L = zeros(NT, 3);
            diffH = zeros(NT-1, 1);
            diffL = zeros(NT-1, 3);
            constraint_position = zeros(NT,m);
            constraint_velocity = zeros(NT,m);

            for j = 1:NT
                %if strcmp(this_simulation.INTEGRATOR,'Ggl_rk')
                %    T(j) = 1/2*v(j,:)*M*v(j,:)';
                %else
                    T(j) = 1 / 2 * p(j, :) * IM' * p(j, :)';
                %end
                V(j) = this_problem.internal_potential(q(j,:)') + this_problem.external_potential(q(j,:)');
                H(j) = T(j) + V(j);
                constraint_position(j,:) = this_problem.constraint(q(j,:)')';
                constraint_velocity(j,:) = (this_problem.constraint_gradient(q(j,:)')*v(j,:)')';
                    
                if DIM == 3
                    
                    for k = 1:d
                        
                        L(j, :) = L(j,:) + cross(q(j,(k-1)*DIM+1:k*DIM), p(j, (k-1)*DIM+1:k*DIM));
                        
                    end
                    
                end

            end
            
            for j = 1:(NT-1)
                
                diffH(j)    = H(j+1) - H(j);
                diffL(j, :) = L(j+1, :) - L(j, :);
                
            end
                       
            this_simulation.T = T;
            this_simulation.V = V;
            this_simulation.H = H;
            this_simulation.L = L;
            this_simulation.Hdiff = diffH;
            this_simulation.Ldiff = diffL;
            this_simulation.constraint_position = constraint_position;
            this_simulation.constraint_velocity = constraint_velocity;

        end
        
        function save(~,export_simulation)
            
            % convert timestep-size to string
            DT_string         = strrep(num2str(export_simulation.DT),'.','');
            integrator_string = strrep(export_simulation.INTEGRATOR,'_','');
            
            % Set export-string-name
            export_folder = [export_simulation.export_path,export_simulation.SYSTEM,'_',integrator_string,'_DT',DT_string,'/'];
                
            
            if export_simulation.should_export
                
                if ~exist(export_folder, 'dir')
                    
                    mkdir(export_folder)
                    
                else
                    
                    warning('off')
                    rmdir(export_folder,'s')
                    mkdir(export_folder)
                    warning('on')
                    fprintf('     Removed existing output folder.                 \n');
                    fprintf('  \n');
                    
                end
                
                fprintf('     Exporting results...                 \n');
                fprintf('  \n');
                                
                % Export
                save([export_folder,'results'],'export_simulation');
                
                if export_simulation.should_export_figures
                    figHandles = findall(0,'Type','figure'); 
                    
                    for i = 1:numel(figHandles)
                        
                        % Check if current figure has a name
                        if ~isempty(figHandles(i).Name)
                            export_name = figHandles(i).Name;
                        else
                            export_name = num2str(i);
                        end
                        
                        % Clear current figures title
                        set(0, 'currentfigure', figHandles(i));
                        titlestring = get(gca,'title').String;
                        title(gca,'');
                        set(findall(gca, 'Type', 'Line'),'LineWidth',1.2);
                        
                        % Export to .eps
                        print(figHandles(i), [export_folder,export_name], '-depsc')
                        % Export to .tikz (requires matlab2tikz/src to be
                        % in the matlab-path)
                        %cleanfigure('handle',figHandles(i));
                        warning('off')
                        matlab2tikz('figurehandle',figHandles(i),'height','\figH','width','\figW','filename',[export_folder,export_name,'.tikz'],'showInfo', false,'floatformat','%.5g');
                        warning('on')
                        title(gca,titlestring);
                        set(findall(gca, 'Type', 'Line'),'LineWidth',1.5);
                        
                    end
                    
                end
                
                fprintf('     ...finished.                 \n');
                fprintf('  \n');
                fprintf('**************************************************** \n');
                
            end
            
        end

        function plot(self,this_simulation)
            
            H = this_simulation.H;
            V = this_simulation.V;
            T = this_simulation.T;
            t = this_simulation.t;
            L = this_simulation.L;
            diffH = this_simulation.Hdiff;
            diffL = this_simulation.Ldiff;
            g_pos = this_simulation.constraint_position;
            g_vel = this_simulation.constraint_velocity;
            
            for i = 1:length(this_simulation.plot_quantities)
                
                fig = figure();
                grid on;
                quantity = this_simulation.plot_quantities{i};
                integrator_string = strrep(this_simulation.INTEGRATOR,'_','-');
            
                switch quantity

                    case 'energy'

                        %plots Energy quantities over time
                        plotline = plot(t, T, t, V, t, H);
                        fig.Name = 'energy';
                        Mmin     = min([min(V), min(T), min(H)]);
                        Mmax     = max([max(V), max(T), max(H)]);
                        ylim([Mmin - 0.1 * abs(Mmax-Mmin), Mmax + 0.1 * abs(Mmax-Mmin)]);
                        title(strcat(integrator_string, ': Energy'));
                        legend('T', 'V', 'H')
                        xlabel('t');
                        
                    case 'angular_momentum'

                        %plots the ang. Mom. about dim-axis over time
                        plotline = plot(t, L(:,:));
                        Lmin     = min(L(:));
                        Lmax     = max(L(:));
                        ylim([Lmin - 0.1 * abs(Lmax-Lmin), Lmax + 0.1 * abs(Lmax-Lmin)]);
                        fig.Name = 'ang_mom';
                        title(strcat(integrator_string, ': Angular Momentum'));
                        legend('L_1','L_2','L_3');
                        xlabel('t');
                        ylabel('L_i(t)');

                    case 'energy_difference'

                        %plots the increments of Hamiltonian over time
                        plotline    = plot(t(1:end-1), diffH);
                        max_diff    = max(diffH);
                        max_rounded = 10^(floor(log10(max_diff))+1);
                        min_diff    = min(diffH);
                        min_rounded = -10^(real(floor(log10(min_diff)))+1);
                        hold on
                        plot([t(1) t(end)],[max_rounded max_rounded],'k--',[t(1) t(end)],[min_rounded min_rounded],'k--');
                        ylim([2*min_rounded 2*max_rounded]);
                        fig.Name = 'H_diff';
                        title(strcat(integrator_string, ': Energy difference'));
                        xlabel('t');
                        ylabel('H^{n+1}-H^{n}');
                        legend(strcat('std(H)=', num2str(std(H))));

                    case 'angular_momentum_difference'

                        %plots the increments of ang. Mom. over time about desired axis (dim)      
                        plotline    = plot(t(1:end-1), diffL(:,:));
                        max_diff    = max(max(diffL));
                        max_rounded = 10^(floor(log10(max_diff))+1);
                        min_diff    = min(min(diffL));
                        min_rounded = -10^(real(floor(log10(min_diff)))+1);
                        hold on
                        plot([t(1) t(end)],[max_rounded max_rounded],'k--',[t(1) t(end)],[min_rounded min_rounded],'k--');
                        ylim([2*min_rounded 2*max_rounded]);
                        fig.Name = 'J_diff';
                        title(strcat(integrator_string, ': Ang. mom. - difference'));
                        xlabel('t');
                        legend('L_1','L_2','L_3');
                        ylabel('L_i^{n+1}-L_i^{n}');
                        legend(strcat('std(L_1)=', num2str(std(L(:,1)))),strcat('std(L_2)=', num2str(std(L(:,2)))),strcat('std(L_3)=', num2str(std(L(:,3)))));

                    case 'constraint_position'

                        %plots the position constraint and their violations by integration
                        plotline    = plot(t,g_pos);
                        max_diff    = max(max(g_pos));
                        max_rounded = 10^(floor(log10(max_diff))+1);
                        min_diff    = min(min(g_pos));
                        min_rounded = -10^(real(floor(log10(min_diff)))+1);
                        hold on
                        plot([t(1) t(end)],[max_rounded max_rounded],'k--',[t(1) t(end)],[min_rounded min_rounded],'k--');
                        ylim([2*min_rounded 2*max_rounded]);
                        
                        fig.Name = 'g_pos';
                        title(strcat(integrator_string, ': Constraint on position level'));
                        xlabel('t');
                        ylabel('g^q_k(t)');

                    case 'constraint_velocity'

                        %plots the velocity constraint and their violations by integration
                        plotline    = plot(t,g_vel);
                        max_diff    = max(max(g_vel));
                        max_rounded = 10^(floor(log10(max_diff))+1);
                        min_diff    = min(min(g_vel));
                        min_rounded = -10^(real(floor(log10(min_diff)))+1);
                        hold on
                        plot([t(1) t(end)],[max_rounded max_rounded],'k--',[t(1) t(end)],[min_rounded min_rounded],'k--');
                        ylim([2*min_rounded 2*max_rounded]);
                        
                        fig.Name = 'g_vel';
                        title(strcat(integrator_string, ': Constraint on velocity level'));
                        xlabel('t');
                        ylabel('g^v_k(t)');    

                    otherwise

                        error(strcat('No plotting routine for ',quantity,'  this quantity defined'));

                end
            
                set(plotline, 'linewidth', 1.5);
                colororder(self.color_scheme);
                                
            end
        
        end
        
        function error = calculate_errors(~,quantity,quantity_ref,num_A,num_B)
            error = zeros(num_A,num_B);
            for i = 1:num_A
                for j = 1:num_B
                    error(i,j) = norm(quantity(:,i,j)-quantity_ref)/norm(quantity_ref);
                end
            end
        end
        
        function convergence_plot(self,h_values,y_values,num_A,legend_entries)  
            
            figure()
            for j = 1:num_A
                loglog(h_values(1:end-1),y_values(1:end-1,j),'-o','Linewidth',1.2)
                %loglog(h_values(:),y_values(:,j),'-o','Linewidth',1.2)
                hold on
            end
            xlim([h_values(end-1)*0.8 h_values(1)*1.2]);
            %xlim([h_values(end)*0.6 h_values(1)*1.4]);
            ylim([min(min(y_values(1:end-1,:)))*0.8 max(max(y_values(1:end-1,:)))*1.2]);
            %ylim([min(min(y_values(:,:)))*0.6 max(max(y_values(:,:)))*1.4]);
            
            colororder(self.color_scheme);
            legend(legend_entries)
            legend('Location','southeast')
            title('relative error')
            grid on
            xlabel('h');
            ylabel('relative error');
            
        end
        
    end

end
