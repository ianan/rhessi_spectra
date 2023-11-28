pro get_mfstats9_a0_org_sep

  ; And produce separate file for each of the 6 detectors (previous work summed these together)
  ; Closer to the original get_srm_spec and do_wee_write_ospex
  ;
  ; 13-Nov-2023 Closer to the original get_srm_spec and do_wee_write_ospex
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
    tr=anytim([anytim(resin[i].bk_bf_tr[0]),anytim(resin[i].fend)],/yoh,/trunc)

    ; Need to loop over each detector
    ; Doing default 1,3,4,5,8,9
    ; If just did sum_flag=0 would save all separate to same file (?)
    ; which some fitting packages don't like
    ; Paper wrong here as code is 1,3,4,6,8,9 NOT 1,3,4,5,8,9 as stated in paper text
    dets=[1,0,1,1,0,1,0,1,1,0,0,0,0,0,0,0,0,0]
    use_det=where(dets eq 1,nud)
    for di=0, nud-1 do begin
      os=hsi_spectrum()
      os->set,obs_time_int=tr
      eres=1/3.
      os->set,sp_energy_binning=3.+findgen(33/eres+1)*eres
      os->set,sp_data_unit='flux'
      os->set,sp_time_interval=4.
      ; Use imaging info to get flare posisiton
      xypos=[resin[i].vf_fit.srcx,resin[i].vf_fit.srcy]
      os-> set, flare_xyoffset=xypos
      os->set,sp_semi_calibrated=0
      os->set,sp_data_str=1
      os->set,decimation_correct= 1
      os->set,rear_decimation_correct= 0
      os->set,pileup_correct= 0

      ; Do it manually per detector
      dets_temp=intarr(18)
      dets_temp[use_det[di]]=1
      print,dets_temp
      os->set,seg_index_mask=dets_temp
      dname='d'+strcompress(string(use_det[di]+1),/rem)
      os-> set, sum_flag= 1
      os->filewrite,/fits,/build,simplify=0,$
        srmfile='mfstats9_fits/'+break_time(resin[i].fpeak)+'_srm_org_'+dname+'_sf1.fits',$
        specfile='mfstats9_fits/'+break_time(resin[i].fpeak)+'_spec_org_'+dname+'_sf1.fits'
      obj_destroy, os
    endfor

  endfor

end