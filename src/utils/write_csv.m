function write_csv(output_file, holo_name, mse_re, mse_im, psnr_abs)
    if ~isfile(output_file)
        fid = fopen(output_file, 'w');
        fprintf(fid, 'holo_name,mse_re,mse_im,psnr_abs\n');
        fprintf(fid, '%s,%f,%f,%f\n', holo_name, mse_re, mse_im, psnr_abs);
        fclose(fid);
    else
        fid = fopen(output_file, 'a');
        fprintf(fid, '%s,%f,%f,%f\n', holo_name, mse_re, mse_im, psnr_abs);
        fclose(fid);
    end
end
