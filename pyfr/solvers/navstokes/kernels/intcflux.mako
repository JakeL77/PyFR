# -*- coding: utf-8 -*-
<%inherit file='base'/>
<%namespace module='pyfr.backends.base.makoutil' name='pyfr'/>

<%include file='pyfr.solvers.baseadvecdiff.kernels.artvisc'/>
<%include file='pyfr.solvers.euler.kernels.rsolvers.${rsolver}'/>
<%include file='pyfr.solvers.navstokes.kernels.flux'/>

<% beta, tau = c['ldg-beta'], c['ldg-tau'] %>

<%pyfr:kernel name='intcflux' ndim='1'
              ul='inout view fpdtype_t[${str(nvars)}]'
              ur='inout view fpdtype_t[${str(nvars)}]'
              gradul='in view fpdtype_t[${str(ndims)}][${str(nvars)}]'
              gradur='in view fpdtype_t[${str(ndims)}][${str(nvars)}]'
              artviscl='in view fpdtype_t'
              artviscr='in view fpdtype_t'
              entminl='in view fpdtype_t'
              entminr='in view fpdtype_t'
              entmin_intl='inout view fpdtype_t'
              entmin_intr='inout view fpdtype_t'
              nl='in fpdtype_t[${str(ndims)}]'
              magnl='in fpdtype_t'>
    // Perform the Riemann solve
    fpdtype_t ficomm[${nvars}], fvcomm;
    ${pyfr.expand('rsolve', 'ul', 'ur', 'nl', 'ficomm')};

% if viscous:
    % if beta != -0.5:
        fpdtype_t fvl[${ndims}][${nvars}] = {{0}};
        ${pyfr.expand('viscous_flux_add', 'ul', 'gradul', 'fvl')};
        ${pyfr.expand('artificial_viscosity_add', 'gradul', 'fvl', 'artviscl')};
    % endif

    % if beta != 0.5:
        fpdtype_t fvr[${ndims}][${nvars}] = {{0}};
        ${pyfr.expand('viscous_flux_add', 'ur', 'gradur', 'fvr')};
        ${pyfr.expand('artificial_viscosity_add', 'gradur', 'fvr', 'artviscr')};
    % endif


    % for i in range(nvars):
        % if beta == -0.5:
            fvcomm = ${' + '.join('nl[{j}]*fvr[{j}][{i}]'.format(i=i, j=j)
                                  for j in range(ndims))};
        % elif beta == 0.5:
            fvcomm = ${' + '.join('nl[{j}]*fvl[{j}][{i}]'.format(i=i, j=j)
                                  for j in range(ndims))};
        % else:
            fvcomm = ${0.5 + beta}*(${' + '.join('nl[{j}]*fvl[{j}][{i}]'
                                                 .format(i=i, j=j)
                                                 for j in range(ndims))})
                   + ${0.5 - beta}*(${' + '.join('nl[{j}]*fvr[{j}][{i}]'
                                                 .format(i=i, j=j)
                                                 for j in range(ndims))});
        % endif
        % if tau != 0.0:
            fvcomm += ${tau}*(ul[${i}] - ur[${i}]);
        % endif

        ul[${i}] =  magnl*(ficomm[${i}] + fvcomm);
        ur[${i}] = -magnl*(ficomm[${i}] + fvcomm);
    % endfor
% else:
    % for i in range(nvars):
        ul[${i}] =  magnl*(ficomm[${i}]);
        ur[${i}] = -magnl*(ficomm[${i}]);
    % endfor
% endif

% if not viscous:
    entmin_intl = entminr;
% endif
</%pyfr:kernel>
