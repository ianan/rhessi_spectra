pro fit_mfstats9_a0_org_saveout

  ; Closer to original wee_2007 setup though using f_thick2 instead of bpow
  ;
  ; Need the following line if don't already have the original data
  ; search_network,/enabled
  ;
  ; 13-Nov-2023 IGH
  ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ; Times from paper microflare list, and found via get_mfstat_times.pro
  restgen, file = 'wee_fig9.genx', resin
  ; At this stage just want b and f
  ids = indgen(6) ; [1,5]
  nf = n_elements(ids)

  tmk2kev = 0.086164
  default, tolerance, 1e-4
  default, max_iter, 75
  default, uncert, 0.02

  ; f_vth
  ; a[0]  em_49, emission measure units of 10^49
  ; a[1]  KT, plasma temperature in keV, restricted to a range from 1.01 MegaKelvin to <998 MegaKelvin in keV
  ; i.e.  0.0870317 - 86.0 keV
  ; a[2]  Relative abundance for Fe, Ni, Si, and Ca. S as well at half the deviation from 1 as Fe.
  ; f_thick2
  ; a(0) - Total integrated electron flux, in units of 10^35 electrons sec^-1.
  ; a(1) - Power-law index of the electron flux distribution function below
  ; eebrk.
  ; a(2) - Break energy in the electron flux distribution function (in keV)
  ; a(3) - Power-law index of the electron flux distribution function above
  ; eebrk.
  ; a(4) - Low energy cutoff in the electron flux distribution function
  ; (in keV).
  ; a(5) - High energy cutoff in the electron flux distribution function (in keV).
  default, fitstart, [1e-2, 11.0 * tmk2kev, 1, 1e-2, 6, 1000, 20, 15, 1000]
  default, fitmin, [1e-5, 5.0 * tmk2kev, 1, 1e-4, 2, 1000, 20, 6, 1000]
  default, fitmax, [1e2, 30. * tmk2kev, 1, 1e2, 13, 1000, 20, 30, 1000]

  for ii = 0, nf - 1 do begin
    i = ids[ii]
    btims = anytim(resin[i].bk_bf_tr, /yoh, /trunc)
    ftims = anytim(resin[i].fpeak_tr, /yoh, /trunc)
    tr = anytim([anytim(resin[i].bk_bf_tr[0]), anytim(resin[i].fend)], /yoh, /trunc)

    print, tr

    set_logenv, 'OSPEX_NOINTERACTIVE', '1'
    o = ospex()
    o->set, spex_fit_manual = 0, spex_fit_reverse = 0, spex_fit_start_method = 'previous_int'
    o->set, spex_autoplot_enable = 0, spex_fitcomp_plot_resid = 0, spex_fit_progbar = 0

    o->set, fit_function = 'vth+thick2'
    o->set, fit_comp_spectrum = ['full', '']
    o->set, fit_comp_model = ['chianti', '']

    o->set, spex_summ_uncert = uncert
    o->set, mcurvefit_itmax = max_iter
    o->set, mcurvefit_tol = tolerance

    o->set, spex_specfile = 'mfstats9_fits/' + break_time(resin[i].fpeak) + '_spec_sum_org.fits'
    o->set, spex_drmfile = 'mfstats9_fits/' + break_time(resin[i].fpeak) + '_srm_sum_org.fits'
    o->set, spex_fit_time_interval = ftims
    o->set, spex_bk_time_interval = btims
    o->set, spex_bk_order = 0
    o->set, fit_comp_minima = fitmin
    o->set, fit_comp_maxima = fitmax

    ; A0 could fit down to 3 keV, but this is the time with bad/noisy detectors so might not work
    o->set, spex_erange = [4, 8]
    o->set, fit_comp_free = [1, 1, 0, 0, 0, 0, 0, 0, 0]
    o->set, fit_comp_param = fitstart
    o->dofit

    ; Workout where the background matches the data
    bksub = o->getdata(class = 'spex_fitint', spex_units = 'flux')
    if datatype(bksub) eq 'STC' then nbk = n_elements(bksub.data)
    ; Or make the minimum 13 keV if all bad occurs before then
    bad = 30
    if datatype(bksub) eq 'STC' then $
      bad = min(where(bksub.data lt 0.0, nbad)) > 30.
    engs = o->getaxis(/ct_energy, /edges_2)
    uppereng = engs[0, bad]

    o->set, spex_erange = [9, uppereng] ; [8,15]
    o->set, fit_comp_free = [0, 0, 0, 1, 1, 0, 0, 1, 0]
    o->dofit
    o->set, spex_erange = [4, uppereng] ; [4,15]
    o->set, fit_comp_free = [1, 1, 0, 1, 1, 0, 0, 1, 0]
    o->dofit

    p = o->get(/spex_summ_params)
    perr = o->get(/spex_summ_sigmas)

    tmkstr = string(p[1] / tmk2kev, format = '(f5.2)') + ' MK'
    em49 = p[0] * 1d49
    em49pow = floor(alog10(em49))
    emstr = string(p[0] * 1e3, format = '(f5.2)') + 'x10!U46!N cm!U-3!N'

    nstr = string(p[3], format = '(f5.2)') + 'x10!U35!N e!U-!Ns!U-1!N'
    delstr = '!Md!3: ' + string(p[4], format = '(f5.2)')
    ecstr = string(p[7], format = '(f5.2)') + ' keV'

    dd = o->getdata(class = 'spex_fitint', spex_units = 'flux')
    fit = o->calc_func_components(spex_units = 'flux', /all_func)
    ee = fit.ct_energy
    chisq = o->get(/spex_summ_chisq)
    mide = o->getaxis(/ct_energy)
    erange = o->get(/spex_erange)

    ftot = fit.yvals[*, 0]
    fth = fit.yvals[*, 1]
    fnn = fit.yvals[*, 2]
    
    osx_p=p
    osx_p[1]=p[1]/tmk2kev
    
    fitvals={ftims:ftims,engs:ee,mide:mide, data_flux:dd.data,edata_flux:dd.edata,$
      back_flux:dd.bkdata,eback_flux:dd.ebkdata,$
      modtot:ftot, modth:fth, modnn:fnn,$
      fit_range:erange,chisq:chisq,osx_p:osx_p}

    savegen,file='res/fitout_'+ break_time(ftims[0]),fitvals
    
    
    obj_destroy, o
  endfor

  stop
end