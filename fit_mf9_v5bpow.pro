pro fit_mf9_v5bpow

  ; Trying to replicate fit to original wee_2007 setup using f_bpow and
  ; f_vth with v5.2 CHIANTI files
  ;
  ; 25-Jan-2024 IGH
  ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ;; Default up to 2006 (v5.2)
  chianti_kev_common_load,contfile='chianti_cont_1_250_v52.sav',linefile='chianti_lines_1_10_v52.sav',/reload
  ;  chianti_kev_common_load,contfile=getenv('CHIANTI_CONT_FILE'),linefile=getenv('CHIANTI_LINES_FILE'),/reload

  ; Times from paper microflare list, and found via get_mfstat_times.pro
  restgen,file='wee_fig9.genx',resin
  ids=indgen(6)
  nf=n_elements(ids)

  ; all from do_weefit_fin.pro
  tmk2kev=0.086164
  default, tolerance, 1e-4;1e-4
  default, max_iter, 50
  default, uncert, 0.0;0.05
  default, bk_order, 0

  ; f_vth
  ;   a[0]  em_49, emission measure units of 10^49
  ;   a[1]  KT, plasma temperature in keV, restricted to a range from 1.01 MegaKelvin to <998 MegaKelvin in keV
  ;     i.e.  0.0870317 - 86.0 keV
  ;   a[2]  Relative abundance for Fe, Ni, Si, and Ca. S as well at half the deviation from 1 as Fe.
  default, fitstart,[1e-2,11.0*tmk2kev,1,1e-3,1.5,9.0,7.0]
  ;   default, fitstart,[1e-2,8.5*tmk2kev,1,1e-2,1.5,12.0,5.0]
  default, fitmin,  [1e-5,5.0*tmk2kev,1,1e-5,1.5, 7.0,2.0]
  default, fitmax,  [1e2 ,30.*tmk2kev,1,1e3 ,1.5,20.0,12.0]

  for ii=0,nf-1 do begin
    ii=3
    i=ids[ii]
    btims=anytim(resin[i].bk_bf_tr,/yoh,/trunc)
    ftims=anytim(resin[i].fpeak_tr,/yoh,/trunc)
    tr=anytim([anytim(resin[i].bk_bf_tr[0]),anytim(resin[i].fend)],/yoh,/trunc)

    print,tr

    set_logenv, 'OSPEX_NOINTERACTIVE', '1'
    o = ospex()
    o->set, spex_fit_manual=0, spex_fit_reverse=0, spex_fit_start_method='previous_int'
    o->set, spex_autoplot_enable=0, spex_fitcomp_plot_resid=0, spex_fit_progbar=0

    o->set, fit_function='vth+bpow'
    o-> set, fit_comp_spectrum= ['full', '']
    o-> set, fit_comp_model= ['chianti', '']

    o->set, spex_uncert=uncert

    ;    o->set, spex_summ_uncert=uncert
    o->set, mcurvefit_itmax=max_iter
    o->set, mcurvefit_tol=tolerance

    o->set, spex_specfile= 'mfstats9_fits/'+break_time(resin[i].fpeak)+'_spec_sum_org.fits'
    o->set, spex_drmfile= 'mfstats9_fits/'+break_time(resin[i].fpeak)+'_srm_sum_org.fits'
    o->set, spex_fit_time_interval=ftims
    o->set,spex_bk_time_interval=btims
    o->set,spex_bk_order=bk_order
    o->set, fit_comp_minima=fitmin
    o->set, fit_comp_maxima=fitmax

    ; A0 could fit down to 3 keV, but this is the time with bad/noisy detectors so might not work
    o->set, spex_erange=[4,8]
    o->set, fit_comp_free = [1,1,0,0,0,0,0,0]
    o->set, fit_comp_param=fitstart
    o->dofit

    ; Workout where the background matches the data
    bksub=o->getdata(class='spex_fitint',spex_units='flux')
    if datatype(bksub) eq 'STC' then nbk=n_elements(bksub.data)
    ; Or make the minimum 13 keV if all bad occurs before then
    bad=30
    if datatype(bksub) eq 'STC' then $
      bad=min(where(bksub.data lt 0.0, nbad)) > 30.
    engs=o->getaxis(/ct_energy,/edges_2)
    uppereng=engs[0,bad]
    upperneg=15

    o->set, spex_erange=[9,uppereng]
    o->set, fit_comp_free=[0,0,0,1,0,1,1]
    o->dofit
    o->set, spex_erange=[4,uppereng]
    o->set, fit_comp_free=[1,1,0,1,0,1,1]
    o->dofit


    p=o-> get(/spex_summ_params)
    perr=o -> get(/spex_summ_sigmas)

    p[1]=p[1]/tmk2kev
    idosx=[0,1,3,5,6]
    print,p[idosx]

    f_50=p[3]
    eb=p[5]
    g1=p[4]
    g2=p[6]
    f_eb=f_50*(eb/50.)^(-1*g1)
    f_1=f_eb*eb^g2
    print,f_1

    ;    So the ospex setup in terms of uncert, tolerance, max_iter,
    ;    start values, energy start/mid-point not making a huge difference
    ;    
    ;    Bigger difference using v5 instead of v7, get T closer to original
    ;    but EM out, and resulting bpow more out than with v7!

    ; "final" 17 Mar 2003
    ; 0.0014224706   12.426785     0.046197537       8.9995346       5.5096469
    ; v5.2 uncert 0 > 4keV
    ; 0.00108108      12.3487     0.163538      7.16740      6.25718
    ; v5.2 uncert 0 > 3keV
    ; 0.00105728      12.3939     0.162822      7.16567      6.25991
    ; v5.2 uncert 0.05 > 4keV
    ; 0.00112771      12.2548     0.163104      7.16756      6.22730
    ; v9 uncert 0 >4keV
    ; 0.000937615      13.1554    0.0882173      7.16558      5.39062
    ; v9 uncert 0 >3keV
    ; 0.000925006      13.1852    0.0872728      7.16613      5.36935

    ; "final" 25 Jul 2003
    ; 0.0031186442       12.961564      0.52228254       8.5484877       5.7524147
    ; v5.2 uncert 0 > 3keV
    ; 0.00254704      12.8602      1.49769      7.17297      6.05396
    ; v5.2 uncert 0 > 3keV different start parameter
    ; 0.00255011      12.8570      1.49965      7.16949      6.05119
    ; v9 uncert 0 >3keV
    ; 0.00228841      13.6793      1.16589      7.31893      5.85647


    stop

    ;    tmkstr=string(p[1]/tmk2kev,format='(f5.2)')+' MK'
    ;    em49=p[0]*1d49
    ;    em49pow=floor(alog10(em49))
    ;    emstr=string(p[0]*1e3,format='(f5.2)')+'x10!U46!N cm!U-3!N'
    ;
    ;    nstr=string(p[3],format='(f5.2)')+' ph s!U-1!N cm!U-2!N keV!U-1!N'
    ;    gamstr='!Mg!3: '+string(p[6],format='(f5.2)')
    ;    ebstr=string(p[5],format='(f5.2)')+' keV'
    ;
    ;    dd = o -> getdata(class='spex_fitint',spex_units='flux')
    ;    fit= o -> calc_func_components(spex_units='flux', /all_func)
    ;    ee=fit.ct_energy
    ;    chisq=o->get(/spex_summ_chisq)
    ;    mide= o -> getaxis(/ct_energy)
    ;    erange=o->get(/spex_erange)
    ;
    ;    ftot=fit.yvals[*,0]
    ;    fth=fit.yvals[*,1]
    ;    fnn=fit.yvals[*,2]
    ;
    ;    @post_outset
    ;    !p.multi=0
    ;    !p.charsize=1.2
    ;    figname='figs/mfl_'+break_time(ftims[0])+'_a0_org15_bpow.eps'
    ;    set_plot,'ps'
    ;    device, /encapsulated, /color, /isolatin1,/inches, $
    ;      bits=8, xsize=6, ysize=5,file=figname
    ;
    ;    !p.thick=4
    ;    tlc_igh
    ;
    ;    yr=[3e-4,3e1]
    ;    xr=[3,30]
    ;    plot_oo,mide,dd.data,psym=1,yrange=yr,ystyle=17,xstyle=17,xrange=xr,ytickf='exp1',$
    ;      xtitle='Energy [keV]',ytitle='counts s!U-1!N cm!U-2!N keV!U-1!N',/nodata,$
    ;      title=ftims[0]+' to '+anytim(ftims[1],/time,/trunc,/yoh)
    ;
    ;    nengs=n_elements(ee[0,*])
    ;    oplot,mide,dd.bkdata,color=10,psym=10
    ;    oplot,mide,dd.data,color=0,psym=10
    ;
    ;    oplot,erange[0]*[1,1],yr,lines=1,thick=2
    ;    oplot,erange[1]*[1,1],[yr[0],10^(alog10(yr[1])-1.5)],lines=1,thick=2
    ;
    ;    xyouts,xr[1]-2,10^(alog10(yr[1])-.4),tmkstr+', '+emstr,align=1,color=25,/data,chars=1.2
    ;    xyouts,xr[1]-2,10^(alog10(yr[1])-.8), nstr+', '+$
    ;      gamstr+', '+ebstr,align=1,color=26,/data,chars=1.2
    ;    xyouts,xr[1]-2,10^(alog10(yr[1])-1.2), '!Mc!3!U2!N: '+string(chisq,format='(f6.2)'),align=1,color=27,/data,chars=1.2
    ;
    ;    oplot,mide,fth,color=25,psym=10
    ;    oplot,mide,fnn,color=26,psym=10
    ;    oplot,mide,ftot,color=27,psym=10
    ;
    ;    xyouts, 5e2,7e2,'data-back',/device,color=0
    ;    xyouts, 5e2,2e2,'back',/device,color=10
    ;
    ;    device,/close
    ;    set_plot, mydevice
    ;    convert_eps2pdf,figname,/del
    ;
    ;    obj_destroy,o

  endfor

  stop

end
