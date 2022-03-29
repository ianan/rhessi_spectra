pro get_mfl20061117_a0

  ; These times/setup are those used in Hannah et. 2008
  ; https://doi.org/10.1051/0004-6361:20079019
  ; This is the oddly non-thermal A-Class event
  ; Was during time of poor RHESSI detector performance so lower energy is problematic
  ;
  ; Entry for this flare in the archive::
  ; https://hesperia.gsfc.nasa.gov/rhessi_extras/flare_images/2006/11/17/20061117_0512_0516/hsi_20061117_0512_0516.html
  ;
  ; Need the following line if don't already have the original data
  ; search_network,/enabled
  ;
  ; 29-Mar-2022 IGH
  ; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  btims='17-Nov-2006 '+['05:13:00','05:13:20']
  ftims='17-Nov-2006 '+['05:13:28','05:13:40']
  tr='17-Nov-2006 '+['05:12:30','05:17:30']

  ;  Make the spectrum and SRM files
  os=hsi_spectrum()
  os->set,obs_time_int=tr
  ;  Do another with the energy binning code 22
  ;https://hesperia.gsfc.nasa.gov/ssw/hessi/dbase/spec_resp/energy_binning.txt
  os->set,sp_energy_binning=22
  ;   Only 1,4,6 good for spectroscopy at this point
  ;  https://hesperia.gsfc.nasa.gov/rhessi_extras/spectra/minute_plots/2006/11/17/hsi_sepdet_spectrum_20061117_051400.png
  os->set,seg_index_mask=[1,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0]
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
  os-> set, sum_flag= 1
  ;Write the file out
  os->filewrite,/fits,/build,simplify=0,$
    srmfile=break_time(tr[0])+'_srm_sum.fits',$
    specfile=break_time(tr[0])+'_spec_sum.fits'

  obj_destroy, os

end
