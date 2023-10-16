pro fit_mfstats9_a0

  ; These times are those used in Hannah et. 2008,
  ; Some examples from the statistics study in Figure 9, doing b and f just now
  ;  https://doi.org/10.1086/529012
  ;
  ; Entry for this flare in the archive (with others - small one during rise of something bigger):
  ; 9b
  ; https://hesperia.gsfc.nasa.gov/rhessi_extras/flare_images/2003/03/17/20030317_1821_1855/hsi_20030317_1821_1855.html
  ; 9f
  ; https://hesperia.gsfc.nasa.gov/rhessi_extras/flare_images/2004/10/24/20041024_0005_0042/hsi_20041024_0005_0042.html
  ;
  ; Need the following line if don't already have the original data
  ; search_network,/enabled
  ;
  ; 29-Mar-2022 IGH
  ; 16-Oct-2023 Now do all 6 from Fig 9 in Hannah et al. 2008 
  ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ; Times from paper microflare list, and found via get_mfstat_times.pro
  restgen,file='wee_fig9.genx',resin
  ;   At this stage just want b and f
  ids=indgen(6);[1,5]
  nf=n_elements(ids)

  for ii=0,nf-1 do begin
    i=ids[ii]
    btims=resin[i].bk_bf_tr
    ftims=resin[i].fpeak_tr
    
    ; Do the spectrum and SRM for
    ; 4 sec before the start of pre-flare background time to 4 sec after flare end time
    tr=anytim([anytim(resin[i].bk_bf_tr[0])-4,anytim(resin[i].fend)+4],/yoh,/trunc)

    print,tr

    set_logenv, 'OSPEX_NOINTERACTIVE', '1'
    o = ospex()
    o->set, spex_fit_manual=0, spex_fit_reverse=0, spex_fit_start_method='previous_int'
    o->set, spex_autoplot_enable=0, spex_fitcomp_plot_resid=0, spex_fit_progbar=0

    o->set, fit_function='vth+thick2'
    o-> set, fit_comp_spectrum= ['full', '']
    o-> set, fit_comp_model= ['chianti', '']

    o->set, spex_summ_uncert=0.05
    o->set, mcurvefit_itmax=75
    o->set, mcurvefit_tol=1e-5

    o-> set, spex_specfile= 'mfstats9_fits/'+break_time(tr[0])+'_spec_sum.fits'
    o-> set, spex_drmfile= 'mfstats9_fits/'+break_time(tr[0])+'_srm_sum.fits'
    o->set, spex_fit_time_interval=ftims
    o->set, fit_comp_param=[1e-3,1.5,1,1e-2,6,1000,20,15,1000]
    o->set,spex_bk_time_interval=btims
    o->set,spex_bk_order=0

    ; A0 could fit down to 3 keV, but this is the time with bad/noisy detectors so might not work
    o->set, spex_erange=[4,8]
    o->set, fit_comp_param=fitstart
    o->set, fit_comp_free = [1,1,0,0,0,0,0,0,0]
    o->dofit
    o->set, spex_erange=[8,15]
    o->set, fit_comp_free=[0,0,0,1,1,0,0,1,0]
    o->dofit
    o->set, spex_erange=[4,15]
    o->set, fit_comp_free=[1,1,0,1,1,0,0,1,0]
    o->dofit

    p=o-> get(/spex_summ_params)
    perr=o -> get(/spex_summ_sigmas)

    tmk2kev=0.086164
    tmkstr=string(p[1]/tmk2kev,format='(f5.2)')+' MK'
    em49=p[0]*1d49
    em49pow=floor(alog10(em49))
    emstr=string(p[0]*1e3,format='(f5.2)')+'x10!U46!N cm!U-3!N'

    nstr=string(p[3],format='(f5.2)')+'x10!U35!N e!U-!Ns!U-1!N'
    delstr='!Md!3: '+string(p[4],format='(f5.2)')
    ecstr=string(p[7],format='(f5.2)')+' keV'

    dd = o -> getdata(class='spex_fitint',spex_units='flux')
    fit= o -> calc_func_components(spex_units='flux', /all_func)
    ee=fit.ct_energy
    chisq=o->get(/spex_summ_chisq)
    mide= o -> getaxis(/ct_energy)
    erange=o->get(/spex_erange)

    ftot=fit.yvals[*,0]
    fth=fit.yvals[*,1]
    fnn=fit.yvals[*,2]

    @post_outset
    !p.multi=0
    !p.charsize=1.2
    figname='figs/mfl_'+break_time(ftims[0])+'_a0.eps'
    set_plot,'ps'
    device, /encapsulated, /color, /isolatin1,/inches, $
      bits=8, xsize=6, ysize=5,file=figname

    !p.thick=4
    tlc_igh

    yr=[3e-4,3e1]
    xr=[3,30]
    plot_oo,mide,dd.data,psym=1,yrange=yr,ystyle=17,xstyle=17,xrange=xr,ytickf='exp1',$
      xtitle='Energy [keV]',ytitle='counts s!U-1!N cm!U-2!N keV!U-1!N',/nodata,$
      title=ftims[0]+' to '+anytim(ftims[1],/time,/trunc,/yoh)

    nengs=n_elements(ee[0,*])
    oplot,mide,dd.bkdata,color=10,psym=10
    oplot,mide,dd.data,color=0,psym=10


    oplot,erange[0]*[1,1],yr,lines=1,thick=2
    oplot,erange[1]*[1,1],[yr[0],10^(alog10(yr[1])-1.5)],lines=1,thick=2

    xyouts,xr[1]-2,10^(alog10(yr[1])-.4),tmkstr+', '+emstr,align=1,color=25,/data,chars=1.2
    xyouts,xr[1]-2,10^(alog10(yr[1])-.8), nstr+', '+$
      delstr+', '+ecstr,align=1,color=26,/data,chars=1.2
    xyouts,xr[1]-2,10^(alog10(yr[1])-1.2), '!Mc!3!U2!N: '+string(chisq,format='(f6.2)'),align=1,color=27,/data,chars=1.2

    oplot,mide,fth,color=25,psym=10
    oplot,mide,fnn,color=26,psym=10
    oplot,mide,ftot,color=27,psym=10

    xyouts, 5e2,7e2,'data-back',/device,color=0
    xyouts, 5e2,2e2,'back',/device,color=10

    device,/close
    set_plot, mydevice
    convert_eps2pdf,figname,/del

    obj_destroy,o

  endfor

  stop

end
