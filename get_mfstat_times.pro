pro get_mfstat_times

  restgen,file='/Users/iain/Library/CloudStorage/Dropbox/work_dbx/wee_2019/mf_final.genx',resin

  ; From Figure 9 in Hannah et al. 2008 https://doi.org/10.1086/529012
  ; Peak time given in the figure
  ptims=['27-Feb-2003 06:22:34','17-Mar-2003 18:41:46','29-Apr-2003 17:43:02',$
    '25-Jul-2003 08:26:42','17-Jan-2004 07:28:46','24-Oct-04 00:31:46']

  arptim=anytim(resin.fpeak)
  ids=intarr(n_elements(ptims))

  for i=0, n_elements(ptims)-1 do begin
    ids[i]=where(anytim(ptims[i]) eq arptim)

    print, ptims[i], ' ---- ', resin[ids[i]].fpeak_tr

  endfor

  resout=resin[ids]

  ; Change time format to something that python can work with
  ;   This gives isot than astropy time works with
  resout.fstart=anytim(resout.fstart,/ccsds)
  resout.fend=anytim(resout.fend,/ccsds)
  resout.fpeak=anytim(resout.fpeak,/ccsds)
  resout.fpeak_tr=anytim(resout.fpeak_tr,/ccsds)
  resout.bk_bf_tr=anytim(resout.bk_bf_tr,/ccsds)
  resout.bk_af_tr=anytim(resout.bk_af_tr,/ccsds)

  savegen,file='wee_fig9',resout

  stop
end