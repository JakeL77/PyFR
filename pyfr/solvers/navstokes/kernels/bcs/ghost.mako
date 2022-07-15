<%namespace module='pyfr.backends.base.makoutil' name='pyfr'/>

<%include file='pyfr.solvers.baseadvecdiff.kernels.artvisc'/>
<%include file='pyfr.solvers.euler.kernels.rsolvers.${rsolver}'/>
<%include file='pyfr.solvers.navstokes.kernels.flux'/>

<% tau = c['ldg-tau'] %>

<%pyfr:macro name='bc_common_flux_state' params='ul, gradul, artviscl, nl, magnl'>
% if viscous:
    // Viscous states
    fpdtype_t ur[${nvars}], gradur[${ndims}][${nvars}];
    ${pyfr.expand('bc_ldg_state', 'ul', 'nl', 'ur')};
    ${pyfr.expand('bc_ldg_grad_state', 'ul', 'nl', 'gradul', 'gradur')};

    // Inviscid (Riemann solve) state
    ${pyfr.expand('bc_rsolve_state', 'ul', 'nl', 'ur')};

    // Perform the Riemann solve
    fpdtype_t ficomm[${nvars}], fvcomm;
    ${pyfr.expand('rsolve', 'ul', 'ur', 'nl', 'ficomm')};

    fpdtype_t fvr[${ndims}][${nvars}] = {{0}};
    ${pyfr.expand('viscous_flux_add', 'ur', 'gradur', 'fvr')};
    ${pyfr.expand('artificial_viscosity_add', 'gradur', 'fvr', 'artviscl')};

    % for i in range(nvars):
    fvcomm = ${' + '.join('nl[{j}]*fvr[{j}][{i}]'.format(i=i, j=j)
                          for j in range(ndims))};
    % if tau != 0.0:
    fvcomm += ${tau}*(ul[${i}] - ur[${i}]);
    % endif

    ul[${i}] = magnl*(ficomm[${i}] + fvcomm);
    % endfor
% else:
    // Inviscid (Riemann solve) state
    fpdtype_t ur[${nvars}], ficomm[${nvars}];
    ${pyfr.expand('bc_rsolve_state', 'ul', 'nl', 'ur')};

    // Perform the Riemann solve
    ${pyfr.expand('rsolve', 'ul', 'ur', 'nl', 'ficomm')};

    % for i in range(nvars):
    ul[${i}] = magnl*ficomm[${i}];
    % endfor
% endif
</%pyfr:macro>
