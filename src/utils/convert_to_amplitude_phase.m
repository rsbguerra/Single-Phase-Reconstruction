function [amp, ph] = convert_to_amplitude_phase(c)
    amp = abs(c);
    ph = angle(c);
end
