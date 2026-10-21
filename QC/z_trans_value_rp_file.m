% Print the z-translation (mm) for one volume from an SPM rp file
rp_file = '/Users/Richard/Documents/20261017_SNORE_QC/37/meanEPI/rp_MFCH02AM140125-0009-00001-000001.txt';
vol     = 2000;   % volume number (1-based)

rp = load(rp_file);   % columns: x, y, z (mm), pitch, roll, yaw (rad)

if vol < 1 || vol > size(rp, 1)
    error('Volume %d is out of range (file has %d volumes).', vol, size(rp, 1));
end

fprintf('Volume %d: Trans Z = %.3f mm\n', vol, rp(vol, 3));