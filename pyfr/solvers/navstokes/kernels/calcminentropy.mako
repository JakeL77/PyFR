# -*- coding: utf-8 -*-
<%inherit file='base'/>
<%namespace module='pyfr.backends.base.makoutil' name='pyfr'/>

<%pyfr:kernel name='calcminentropy' ndim='1'
              entmin_int='in fpdtype_t[${str(nfpts)}]'
              entmin='out fpdtype_t'>

% for i in range(nfpts):
    entmin = fmin(entmin, entmin_int[${i}]);
% endfor

</%pyfr:kernel>
