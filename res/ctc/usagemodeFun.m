function res = usagemodeFun(x, doIndividual)
    if (nargin == 1), doIndividual = false; end
    if (doIndividual), s = 'individual'; else, s = 'exhaustive'; end
    usagemodeStr = {s, 'dynamic'};
    res = usagemodeStr{x + 1}; % To be used as: usagemodeFun(Hobj.doDynamic)
end
