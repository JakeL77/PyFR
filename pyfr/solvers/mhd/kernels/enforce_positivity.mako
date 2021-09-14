# -*- coding: utf-8 -*-
<%inherit file='base'/>
<%namespace module='pyfr.backends.base.makoutil' name='pyfr'/>

<%pyfr:kernel name='enforce_positivity' ndim='2'
              u='inout fpdtype_t[${str(nvars)}]'>

<% tol = 1e-3 %>

u[0] = fmax(${tol}, u[0]);
fpdtype_t invrho = 1.0/u[0];
% if ndims == 2:
    fpdtype_t E = u[6];

    // Compute the velocities
    fpdtype_t rhov[${ndims}], B[${ndims}];
    % for i in range(ndims):
        rhov[${i}] = u[${i + 1}];
        B[${i}] = u[${i + 3}];
    % endfor
    fpdtype_t p = ${c['gamma'] - 1}*(E - 0.5*invrho*(${pyfr.dot('rhov[{i}]', i=ndims)}) - 0.5*(${pyfr.dot('B[{i}]', i=ndims)}));
    u[6] = p > ${tol} ? u[6] : ${tol/(c['gamma'] - 1)} + 0.5*invrho*(${pyfr.dot('rhov[{i}]', i=ndims)}) + 0.5*(${pyfr.dot('B[{i}]', i=ndims)});

% elif ndims == 3:
    fpdtype_t E = u[8];

    // Compute the velocities
    fpdtype_t rhov[${ndims}], B[${ndims}];
    % for i in range(ndims):
        rhov[${i}] = u[${i + 1}];
        B[${i}] = u[${i + 4}];
    % endfor

    fpdtype_t p = ${c['gamma'] - 1}*(E - 0.5*invrho*(${pyfr.dot('rhov[{i}]', i=ndims)}) - 0.5*(${pyfr.dot('B[{i}]', i=ndims)}));
    u[8] = p > ${tol} ? u[8] : ${tol/(c['gamma'] - 1)} + 0.5*invrho*(${pyfr.dot('rhov[{i}]', i=ndims)}) + 0.5*(${pyfr.dot('B[{i}]', i=ndims)});

% endif



</%pyfr:kernel>

