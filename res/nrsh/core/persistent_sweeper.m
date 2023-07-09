function [] = persistent_sweeper(rec_method)
    %PERSISTENT_SWEEPER clear persistent variables created during the
    %reconstructions.


    switch lower(rec_method)
        case 'asm'
            clear rec_asm
        case 'fresnel'
            clear rec_fresnel
        case 'fourier-fresnel'
            clear rec_fourier_fresnel
        otherwise
            warning('nrsh:num_rec:method', 'Warning in nrsh: unknown reconstruction method. Persistent variables clean failed.')
    end

end
