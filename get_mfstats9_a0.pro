pro get_mfstats9_a0

  ; These times are those used in Hannah et. 2008,
  ; Some examples from the statistics study in Figure 9, doing all now
  ;  https://doi.org/10.1086/529012
  ;
  ; Entry for this flare in the archive (with others - small one during rise of something bigger):
  ; 9b
  ; https://hesperia.gsfc.nasa.gov/rhessi_extras/flare_images/2003/03/17/20030317_1821_1855/hsi_20030317_1821_1855.html
  ; 9f
  ; https://hesperia.gsfc.nasa.gov/rhessi_extras/flare_images/2004/10/24/20041024_0005_0042/hsi_20041024_0005_0042.html
  ; Can find the archive entries for the other flares in the figure
  ;
  ; 29-Mar-2022 IGH
  ; 12-Oct-2023 Do all of them now and save in new directory mfstats9_fits/
  ; 06-Nov-2023 Increase time range to +/- 16s
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
    ; Do the spectrum and SRM for
    ; 4 sec before the start of pre-flare background time to 4 sec after flare end time
    tr=anytim([anytim(resin[i].bk_bf_tr[0])-16,anytim(resin[i].fend)+16],/yoh,/trunc)

    print,tr

    ;  Make the spectrum and SRM files
    os=hsi_spectrum()
    os->set,obs_time_int=tr
    eres=1/3.
    os->set,sp_energy_binning=3.+findgen(27/eres+1)*eres
    ;  In paper used 134589 as best during early mission
    os->set,seg_index_mask=[1,0,1,1,1,0,0,1,1,0,0,0,0,0,0,0,0,0]
    os->set,sp_data_unit='rate'
    os->set,sp_time_interval=4.
    os-> set, use_flare_xyoffset= 1
    ; make sure using full DRM
    os->set,sp_semi_calibrated=0
    ; Setup everything else
    os-> set, decimation_correct= 1
    os-> set, rear_decimation_correct= 0
    ;   Don't need pileup correct in the microflares
    os-> set, pileup_correct= 0
    os-> set, sum_flag=1
    os->filewrite,/fits,/build,simplify=0,$
      srmfile='mfstats9_fits/'+break_time(tr[0])+'_srm_sum.fits',$
      specfile='mfstats9_fits/'+break_time(tr[0])+'_spec_sum.fits'

    obj_destroy, os
  endfor

end
