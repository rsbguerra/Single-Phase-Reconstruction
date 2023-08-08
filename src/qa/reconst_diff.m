function [am_diff, ph_diff] = reconst_diff(original_hologram, single_phase_hologram)
    [original_am, original_ph] = convert_to_amplitude_phase(original_hologram);
    [single_am, single_ph] = convert_to_amplitude_phase(single_phase_hologram);

    ph_diff = original_ph - single_ph;
    am_diff = original_am - single_am;

end
