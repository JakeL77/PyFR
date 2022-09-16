# -*- coding: utf-8 -*-

from pyfr.solvers.baseadvec import (BaseAdvectionIntInters,
                                    BaseAdvectionMPIInters,
                                    BaseAdvectionBCInters)

class MPFluidIntIntersMixin:
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.nspec = self.cfg.getint('solver', 'species')

        if self.cfg.get('solver', 'shock-capturing') == 'entropy-filter':
            self._be.pointwise.register('pyfr.solvers.mpeuler.kernels.intcent')

            self.kernels['comm_entropy'] = lambda: self._be.kernel(
                'intcent', tplargs={}, dims=[self.ninters],
                entmin_lhs=self._entmin_lhs, entmin_rhs=self._entmin_rhs
            )


class MPFluidMPIIntersMixin:
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.nspec = self.cfg.getint('solver', 'species')

        if self.cfg.get('solver', 'shock-capturing') == 'entropy-filter':
            self._be.pointwise.register('pyfr.solvers.mpeuler.kernels.mpicent')

            self.kernels['comm_entropy'] = lambda: self._be.kernel(
                'mpicent', tplargs={}, dims=[self.ninters],
                entmin_lhs=self._entmin_lhs, entmin_rhs=self._entmin_rhs
            )


class MPEulerIntInters(MPFluidIntIntersMixin, BaseAdvectionIntInters):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self._be.pointwise.register('pyfr.solvers.mpeuler.kernels.intcflux')

        rsolver = self.cfg.get('solver-interfaces', 'riemann-solver')
        tplargs = dict(ndims=self.ndims, nvars=self.nvars, nspec=self.nspec,
                       rsolver=rsolver, c=self.c)

        self.kernels['comm_flux'] = lambda: self._be.kernel(
            'intcflux', tplargs=tplargs, dims=[self.ninterfpts],
            ul=self._scal_lhs, ur=self._scal_rhs, nl=self._pnorm_lhs
        )


class MPEulerMPIInters(MPFluidMPIIntersMixin, BaseAdvectionMPIInters):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self._be.pointwise.register('pyfr.solvers.mpeuler.kernels.mpicflux')

        rsolver = self.cfg.get('solver-interfaces', 'riemann-solver')
        tplargs = dict(ndims=self.ndims, nvars=self.nvars, nspec=self.nspec,
                       rsolver=rsolver, c=self.c)

        self.kernels['comm_flux'] = lambda: self._be.kernel(
            'mpicflux', tplargs, dims=[self.ninterfpts],
            ul=self._scal_lhs, ur=self._scal_rhs, nl=self._pnorm_lhs
        )


class MPEulerBaseBCInters(BaseAdvectionBCInters):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.nspec = self.cfg.getint('solver', 'species')

        self._be.pointwise.register('pyfr.solvers.mpeuler.kernels.bccflux')

        rsolver = self.cfg.get('solver-interfaces', 'riemann-solver')
        tplargs = dict(ndims=self.ndims, nvars=self.nvars, nspec=self.nspec,
                       rsolver=rsolver, c=self.c, bctype=self.type, 
                       ninters=self.ninters)

        self.kernels['comm_flux'] = lambda: self._be.kernel(
            'bccflux', tplargs=tplargs, dims=[self.ninterfpts],
            extrns=self._external_args, ul=self._scal_lhs, nl=self._pnorm_lhs,
            **self._external_vals
        )

        if self.cfg.get('solver', 'shock-capturing') == 'entropy-filter':
            self._be.pointwise.register('pyfr.solvers.mpeuler.kernels.bccent')

            self.kernels['comm_entropy'] = lambda: self._be.kernel(
                'bccent', tplargs=tplargs, dims=[self.ninterfpts],
                extrns=self._external_args, entmin_lhs=self._entmin_lhs,
                nl=self._pnorm_lhs, ul=self._scal_lhs, **self._external_vals
            )


class MPEulerSupInflowBCInters(MPEulerBaseBCInters):
    type = 'sup-in-fa'

    def __init__(self, be, lhs, elemap, cfgsect, cfg):
        super().__init__(be, lhs, elemap, cfgsect, cfg)

        rho = [f'rho{i}' for i in range(self.nspec)]
        alpha = [f'alpha{i}' for i in range(self.nspec - 1)]
        self.c |= self._exp_opts(
            (rho + alpha + ['p', 'u', 'v', 'w'])[:self.ndims + 2*self.nspec],
            lhs)


class MPEulerSupOutflowBCInters(MPEulerBaseBCInters):
    type = 'sup-out-fn'
    cflux_state = 'ghost'


class MPEulerCharRiemInvBCInters(MPEulerBaseBCInters):
    type = 'char-riem-inv'

    def __init__(self, be, lhs, elemap, cfgsect, cfg):
        super().__init__(be, lhs, elemap, cfgsect, cfg)

        rho = [f'rho{i}' for i in range(self.nspec)]
        alpha = [f'alpha{i}' for i in range(self.nspec - 1)]
        self.c |= self._exp_opts(
            (rho + alpha + ['p', 'u', 'v', 'w'])[:self.ndims + 2*self.nspec],
            lhs)


class MPEulerSlpAdiaWallBCInters(MPEulerBaseBCInters):
    type = 'slp-adia-wall'
