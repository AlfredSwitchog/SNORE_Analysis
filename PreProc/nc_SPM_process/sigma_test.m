
%calculations are from this github page: https://github.com/rordenlab/spmScripts/blob/master/fsl_temporal_filt.m
%need to devide by TR to get the sigma per volume 
Hz_cutoff = 0.01;
TR = 2.5;
%(2*sqrt(2*log(2))) = 2.3548
sigma_stand = ((1./Hz_cutoff)./2)./TR;
sigma_alt = ((1./Hz_cutoff)./sqrt(8*log(2)))./TR; 
sigma_gpt = ((1./Hz_cutoff)/ 2.3548)/TR;

disp(['sigma_stand: ', num2str(sigma_stand)])
disp(['sigma_alt: ', num2str(sigma_alt)])