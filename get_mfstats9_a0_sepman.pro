pro get_mfstats9_a0_sepman

  ; Produce the SRM and spectra fits for each of the microflares in Hannah et. 2008, Figure 9
  ; 
  ; And produce separate file for each of the 6 detectors (previous work summed these together)
  ;
  ; 12-Oct-2023 IGH
  ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ; Need the following line if don't already have the original data
  search_network,/enabled

  ; Times from paper microflare list, and found via get_mfstat_times.pro
  restgen,file='wee_fig9.genx',resin
  ;   Do all of them
  ids=indgen(n_elements(resin.fstart))
  nf=n_elements(ids)
  
  for ii=0,nf-1 do begin
    i=ids[ii]
    btims=resin[i].bk_bf_tr
    ftims=resin[i].fpeak_tr
    ; Do the spectrum and SRM for
    ; 4 sec before the start of pre-flare background time to 4 sec after flare end time
    tr=anytim([anytim(resin[i].bk_bf_tr[0])-4,anytim(resin[i].fend)+4],/yoh,/trunc)
    
    ; Need to loop over each detector
    ; Doing default 1,3,4,6,8,9
    ; If just did sum_flag=0 would save all separate to same file (?) 
    ; which some fitting packages don't like
    
    dets=[1,0,1,1,0,1,0,1,1,0,0,0,0,0,0,0,0,0]
    use_det=where(dets eq 1,nud)
    for i=0, nud-1 do begin
      ;  Make the spectrum and SRM files
      os=hsi_spectrum()
      os->set,obs_time_int=tr
      ; Energy 1/3 keV binning 3-100 keV with
      eres=1/3.
      os->set,sp_energy_binning=3.+findgen(97/eres+1)*eres

      os->set,seg_index_mask=dets
      os->set,sp_data_unit='rate'
      os->set,sp_time_interval=4.
      os-> set, use_flare_xyoffset= 1
      ; make sure using full DRM
      os->set,sp_semi_calibrated=0
      ; Setup everything else
      os-> set, decimation_correct= 1
      os-> set, rear_decimation_correct= 0
      os-> set, pileup_correct= 1

      ; Do it manually per detector
      dets_temp=intarr(18)
      dets_temp[use_det[i]]=1
      print,dets_temp
      os->set,seg_index_mask=dets_temp
      dname='d'+strcompress(string(use_det[i]+1),/rem)
      os-> set, sum_flag= 0
      os->filewrite,/fits,/build,simplify=0,$
        srmfile='mfstats9_fits/'+break_time(tr[0])+'_srm_'+dname+'.fits',$
        specfile='mfstats9_fits/'+break_time(tr[0])+'_spec_'+dname+'.fits'
      obj_destroy, os
    endfor
    
   endfor
  
 end