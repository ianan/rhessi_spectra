pro get_mfstats9_a0_sepman_org

  ; Closer to the original get_srm_spec and do_wee_write_ospex
  ; 
  ; 13-Nov-2023 Closer to the original get_srm_spec and do_wee_write_ospex
  ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ; Need the following line if don't already have the original data
  search_network,/enabled

  ; Times from paper microflare list, and found via get_mfstat_times.pro
  ;  Changed time format in wee_fig9.genx to isot for python but should still work here
  ;  As doing an anytim() before giving the times to the object
  restgen,file='wee_fig9.genx',resin
  ;  ;   At this stage just want b and f
  ;  ids=[1,5]
  ;   Now do all of them
  ids=indgen(n_elements(resin.fstart))
  nf=n_elements(ids)

  for ii=0,nf-1 do begin
    i=ids[ii]
    btims=resin[i].bk_bf_tr
    ftims=resin[i].fpeak_tr
    ; Do the spectrum and SRM for exactly time range of old data
    tr=anytim([anytim(resin[i].bk_bf_tr[0]),anytim(resin[i].fend)],/yoh,/trunc)

    print,tr
    
    ;  Make the spectrum and SRM files
    os=hsi_spectrum()
    os->set,obs_time_int=tr
    eres=1/3.
    os->set,sp_energy_binning=3.+findgen(33/eres+1)*eres
    ; Paper wrong here as code is 1,3,4,6,8,9 NOT 1,3,4,5,8,9 as stated in paper text
    seg_index_mask=[1,0,1,1,0,1,0,1,1,0,0,0,0,0,0,0,0,0]
    os->set,seg_index_mask=seg_index_mask
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
    os->set,sum_flag=1
    os->filewrite,/fits,/buildsrm,all_simplify=0,$
      srmfile='mfstats9_fits/'+break_time(resin[i].fpeak)+'_srm_sum_org.fits',$
      specfile='mfstats9_fits/'+break_time(resin[i].fpeak)+'_spec_sum_org.fits',/create

    obj_destroy, os
  endfor

end
