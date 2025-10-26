pro get_fl20021005_a1_sepman_sf1

  ; These times/setup are those used in Flecther et. 2007, flare #3
  ;  https://doi.org/10.1086/510446
  ;
  ; Entry for this flare in the archive:
  ; https://hesperia.gsfc.nasa.gov/rhessi_extras/flare_images/2002/10/05/20021005_1040_1056/hsi_20021005_1040_1056.html
  ;
  ; 29-Mar-2022 IGH
  ; 01-Apr-2022 IGH Manually produce per det
  ; 26-Oct-2025 IGH Need to set sum_flag=1 even though sep det due to sunkit-spex "bug"
  ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ; Need the following line if don't already have the original data
  search_network,/enabled

  btims='05-Oct-2002 '+['10:38:32','10:40:32']
  ftims='05-Oct-2002 '+['10:41:20','10:42:24']
  tr='05-Oct-2002 '+['10:38:00','10:44:24']

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
    os->set,sp_data_unit='flux'
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
    os-> set, sum_flag= 1
    os->filewrite,/fits,/build,simplify=0,$
      srmfile='fits/'+break_time(tr[0])+'_srm_'+dname+'_sf1.fits',$
      specfile='fits/'+break_time(tr[0])+'_spec_'+dname+'_sf1.fits'
    obj_destroy, os
  endfor

end
