# -*- coding: utf-8 -*-
<%namespace module='pyfr.backends.base.makoutil' name='pyfr'/>
<%include file='pyfr.solvers.euler.kernels.flux'/>

<%pyfr:macro name='rsolve' params='ul, ur, n, nf'>
    // Compute the left and right fluxes + velocities and pressures
    fpdtype_t fl[${ndims}][${nvars}], fr[${ndims}][${nvars}];

    ${pyfr.expand('inviscid_flux', 'ul', 'fl')};
    ${pyfr.expand('inviscid_flux', 'ur', 'fr')};

    // Sum the left and right velocities and take the normal
    fpdtype_t nvl = ${pyfr.dot('n[{i}]', 'ul[{i}]', i=ndims)};
    fpdtype_t nvr = ${pyfr.dot('n[{i}]', 'ur[{i}]', i=ndims)};
    fpdtype_t nv = max(abs(nvl), abs(nvr));

    // Output
% for i in range(nvars):
    nf[${i}] = 0.5*(${' + '.join('n[{j}]*(fl[{j}][{i}] + fr[{j}][{i}])'
                                 .format(i=i, j=j) for j in range(ndims))})
             + 0.5*nv*(ul[${i}] - ur[${i}]);
% endfor
</%pyfr:macro>
