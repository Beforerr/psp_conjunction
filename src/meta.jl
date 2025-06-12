# https://github.com/PainterQubits/Unitful.jl/issues/649

baremodule YLabel
    B = "B (nT)"
    V = "V (km s⁻¹)"
    n = "n (cm⁻³)"
    ΔV = "ΔV (km/s)"
    T = "T (eV)"
    J = "J (nA m⁻²)"
end


module Labels
    using LaTeXStrings

    B = ["Bx", "By", "Bz", "Magnitude"]
    B_RTN = [L"B_R", L"B_T", L"B_N", L"B"]
    B_LMN = [L"B_L", L"B_M", L"B_N", L"B"]
    B_XYZ = [L"B_X", L"B_Y", L"B_Z", L"B"]

    V = ["Vx", "Vy", "Vz", "Magnitude"]
    V_RTN = [L"V_R", L"V_T", L"V_N", L"|V\;|"]
    V_LMN = [L"V_L", L"V_M", L"V_N"]
    Va_LMN = [L"V_{A, L}", L"V_{A, M}", L"V_{A, N}"]
    V_XYZ = [L"V_X", L"V_Y", L"V_Z", L"|V\;|"]

    J = [L"J_X", L"J_Y", L"J_∥", L"J_⊥"]
end
