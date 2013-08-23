# -*- coding: utf-8 -*-

<%namespace name='util' module='pyfr.backends.openmp.makoutil' />
<%include file='common.h.mako' />

static NOINLINE void
negdivconf_aux(size_t neles,
               ${util.arr_args('tdivtconf', [nvars])},
               const ${dtype} *restrict rcpdjac)
{
    ${util.arr_align('tdivtconf', [nvars])};
    ASSUME_ALIGNED(rcpdjac);

    for (size_t eidx = 0; eidx < neles; eidx++)
    {
    % for i in range(nvars):
        tdivtconf${i}[eidx] *= -rcpdjac[eidx];
    % endfor
    }
}

void
negdivconf(size_t nupts, size_t neles,
           ${dtype} *tdivtconf, const ${dtype} *rcpdjac,
           size_t ldr, size_t lsdt)
{
    #pragma omp parallel for
    for (size_t uidx = 0; uidx < nupts; uidx++)
    {
        negdivconf_aux(neles,
                       ${', '.join('tdivtconf + (uidx*{} + {})*lsdt'
                                   .format(nvars, i)
                                   for i in range(nvars))},
                       rcpdjac + uidx*ldr);
    }
}
