pro fitplot_20030725_tt

  ; Example fit and plot of one of the microflares
  ;
  ; 9-Jul-2024 IGH
  ;
  ;---------

  chianti_kev_common_load,contfile='chianti_cont_1_250_v52.sav',linefile='chianti_lines_1_10_v52.sav',/reload


  restgen, file = '../wee_fig9.genx', resin
  ids = 3
  nf = n_elements(ids)

  tmk2kev=0.086164
  default, tolerance, 1e-4; old run 1e-4, 1e-3 is default
  default, max_iter, 50 ; old run did 50, 10 is default
  default, uncert, 0.0 ; old run did 0, 0.02 is default (more for high count rate)
  default, bk_order, 0


  default, fitstart, [1e-2, 11.0 * tmk2kev, 1, 1e-1, 8.0, 1e3, 10.0, 10.0, 1e3]
  default, fitmin, [1e-5, 5.0 * tmk2kev, 1, 1e-2, 3.0, 1e0, 1.1, 7, 1e2]
  default, fitmax, [1e2, 30. * tmk2kev, 1, 1e2, 13.0, 1e5, 20.0, 30.0, 1e7]

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

    o.set, fit_function = 'vth+thick2'
    o.set, fit_comp_spectrum = ['full', '']
    o.set, fit_comp_model = ['chianti', '']

    o->set, spex_summ_uncert = uncert
    o->set, mcurvefit_itmax = max_iter
    o->set, mcurvefit_tol = tolerance

    o->set, spex_specfile = '../mfstats9_fits/' + break_time(resin[i].fpeak) + '_spec_sum_org.fits'
    o->set, spex_drmfile = '../mfstats9_fits/' + break_time(resin[i].fpeak) + '_srm_sum_org.fits'
    o->set, spex_fit_time_interval = ftims
    o->set, spex_bk_time_interval = btims
    o->set, spex_bk_order = 0
    o->set, fit_comp_minima = fitmin
    o->set, fit_comp_maxima = fitmax

    o.set, spex_erange = [4, 8]
    o.set, fit_comp_free = [1, 1, 0, 0, 0, 0, 0, 0, 0]
    o.set, fit_comp_param = fitstart
    o.dofit

    bksub = o.getdata(class = 'spex_fitint', spex_units = 'flux')
    if datatype(bksub) eq 'STC' then nbk = n_elements(bksub.data)
    bad = 30
    if datatype(bksub) eq 'STC' then $
      bad = min(where(bksub.data lt 0.0, nbad)) > 30.
    engs = o.getaxis(/ct_energy, /edges_2)
    uppereng = engs[0, bad]

    o.set, spex_erange = [9, uppereng]
    o.set, fit_comp_free = [0, 0, 0, 1, 1, 0, 0, 1, 0]
    o.dofit
    o.set, spex_erange = [4, uppereng]
    o.set, fit_comp_free = [1, 1, 0, 1, 1, 0, 0, 1, 0]
    o.dofit

    p = o.get(/spex_summ_params)
    perr = o.get(/spex_summ_sigmas)
   

    tmkstr = string(p[1] / tmk2kev, format = '(f5.2)')+string(177b)+string(perr[1] / tmk2kev, format = '(f5.2)') + ' MK'
    em49 = p[0] * 1d49
    em49pow = floor(alog10(em49))
    emstr = string(p[0] * 1e3, format = '(f5.2)')+string(177b)+string(perr[0] * 1e3, format = '(f5.2)') + 'x10!U46!N cm!U-3!N'

;    nstr = string(p[3], format = '(f5.2)') + 'x10!U35!N e!U-!Ns!U-1!N'
    delstr = '!Md!3: ' + string(p[4], format = '(f5.2)')+string(177b)+string(perr[4], format = '(f5.2)')
    ecstr = 'E!DC!N: ' + string(p[7], format = '(f5.2)')+string(177b)+string(perr[7], format = '(f5.2)') + ' keV'

    dd = o.getdata(class = 'spex_fitint', spex_units = 'flux')
    fit = o.calc_func_components(spex_units = 'flux', /all_func)
    ee = fit.ct_energy
    chisq = o.get(/spex_summ_chisq)
    mide = o.getaxis(/ct_energy)
    erange = o.get(/spex_erange)

    ftot = fit.yvals[*, 0]
    fth = fit.yvals[*, 1]
    fnn = fit.yvals[*, 2]

    @post_outset
    !p.multi = 0
    !p.charsize = 1.2
    figname = 'mfl_' + break_time(ftims[0]) + '_tt.eps'
        set_plot, 'ps'
    device, /encapsulated, /color, /isolatin1, /inches, $
      bits = 8, xsize = 5, ysize = 5, file = figname

    !p.thick = 4
    tlc_igh

    yr = [3e-4, 8e1]
    xr = [3, 30]
    plot_oo, mide, dd.data, psym = 1, yrange = yr, ystyle = 17, xstyle = 17, xrange = xr, ytickf = 'exp1', $
      xtitle = 'Energy [keV]', ytitle = 'counts s!U-1!N cm!U-2!N keV!U-1!N', /nodata, $
      title = 'v5.2 + thick2'

    nengs = n_elements(ee[0, *])
    oplot, mide, dd.bkdata, color = 10, psym = 10
    oplot, mide, dd.data, color = 0, psym = 10

;    oplot, erange[0] * [1, 1], yr, lines = 1, thick = 2
;    oplot, erange[1] * [1, 1], [yr[0], 10 ^ (alog10(yr[1]) - 1.5)], lines = 1, thick = 2
    oplot, erange,yr[1]*[0.9,0.9],thick=10,color=27

    xyouts, xr[1] - 2, 10 ^ (alog10(yr[1]) - .4), tmkstr + ', ' + emstr, align = 1, color = 25, /data, chars = 1.2
    xyouts, xr[1] - 2, 10 ^ (alog10(yr[1]) - .8), delstr + ', ' + ecstr, align = 1, color = 26, /data, chars = 1.2
    xyouts, xr[1] - 2, 10 ^ (alog10(yr[1]) - 1.2), '!Mc!3!U2!N: ' + string(chisq, format = '(f6.2)'), align = 1, color = 27, /data, chars = 1.2

    oplot, mide, fth, color = 25, psym = 10
    oplot, mide, fnn, color = 26, psym = 10
    oplot, mide, ftot, color = 27, psym = 10

    xyouts, 5e2, 2e2, ftims[0] , /device, color = 0,chars=0.9
    xyouts, 5e2, 7e2, 'data-back', /device, color = 0,chars=0.9
    xyouts, 5e2, 12e2, 'back', /device, color = 10,chars=0.9

    device, /close
    set_plot, mydevice
    convert_eps2pdf, figname, /del

    obj_destroy, o
  endfor


  stop
end