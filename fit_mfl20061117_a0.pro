pro fit_mfl20061117_a0

  ; These times/setup are those used in Hannah et. 2008
  ; https://doi.org/10.1051/0004-6361:20079019
  ; This is the oddly non-thermal A-Class event
  ; Was during time of poor RHESSI detector performance so lower energy is problematic
  ;
  ; Entry for this flare in the archive::
  ; https://hesperia.gsfc.nasa.gov/rhessi_extras/flare_images/2006/11/17/20061117_0512_0516/hsi_20061117_0512_0516.html
  ;
  ; Fits files produced from get_mfl20061117_a0.pro
  ;
  ; 29-Mar-2022 IGH
  ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  btims='17-Nov-2006 '+['05:13:00','05:13:20']
  ftims='17-Nov-2006 '+['05:13:28','05:13:40']
  tr='17-Nov-2006 '+['05:12:30','05:17:30']

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

  o-> set, spex_specfile= 'fits/'+break_time(tr[0])+'_spec_sum.fits'
  o-> set, spex_drmfile= 'fits/'+break_time(tr[0])+'_srm_sum.fits'
  o->set, spex_fit_time_interval=ftims
  o->set, fit_comp_param=[1e-3,1.5,1,1e-2,6,1000,20,15,1000]
  o->set,spex_bk_time_interval=btims
  o->set,spex_bk_order=0

  ; A0 could fit down to 3 keV, but this is the time with bad/noisy detectors so might not work
  o->set, spex_erange=[4,12]
  o->set, fit_comp_param=fitstart
  o->set, fit_comp_free = [1,1,0,0,0,0,0,0,0]
  o->dofit
  o->set, spex_erange=[12,45]
  o->set, fit_comp_free=[0,0,0,1,1,0,0,1,0]
  o->dofit
  o->set, spex_erange=[4,45]
  o->set, fit_comp_free=[1,1,0,1,1,0,0,1,0]
  o->dofit

  p=o-> get(/spex_summ_params)
  perr=o -> get(/spex_summ_sigmas)

  tmk2kev=0.086164
  tmkstr=string(p[1]/tmk2kev,format='(f5.2)')+' MK'
  em49=p[0]*1d49
  em49pow=floor(alog10(em49))
  emstr=string(p[0]*1e5,format='(f5.2)')+'x10!U44!N cm!U-3!N'

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

  yr=[3e-4,3e0]
  xr=[3,100]
  plot_oo,mide,dd.data,psym=1,yrange=yr,ystyle=17,xstyle=17,xrange=xr,ytickf='exp1',$
    xtitle='Energy [keV]',ytitle='counts s!U-1!N cm!U-2!N keV!U-1!N',/nodata,$
    title=ftims[0]+' to '+anytim(ftims[1],/time,/trunc,/yoh)

  nengs=n_elements(ee[0,*])
  oplot,mide,dd.bkdata,color=10,psym=10
  oplot,mide,dd.data,color=0,psym=10


  oplot,erange[0]*[1,1],yr,lines=1,thick=2
  oplot,erange[1]*[1,1],[yr[0],10^(alog10(yr[1])-1.5)],lines=1,thick=2

  xyouts,xr[1]-10,10^(alog10(yr[1])-.4),tmkstr+', '+emstr,align=1,color=25,/data,chars=1.2
  xyouts,xr[1]-10,10^(alog10(yr[1])-.8), nstr+', '+$
    delstr+', '+ecstr,align=1,color=26,/data,chars=1.2
  xyouts,xr[1]-10,10^(alog10(yr[1])-1.2), '!Mc!3!U2!N: '+string(chisq,format='(f6.2)'),align=1,color=27,/data,chars=1.2

  oplot,mide,fth,color=25,psym=10
  oplot,mide,fnn,color=26,psym=10
  oplot,mide,ftot,color=27,psym=10

  xyouts, 5e2,7e2,'data-back',/device,color=0
  xyouts, 5e2,2e2,'back',/device,color=10

  device,/close
  set_plot, mydevice
  convert_eps2pdf,figname,/del

  obj_destroy,o

  stop

end
