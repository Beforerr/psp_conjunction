begin
    B_ylabel = ulabel("B", "nT")
    B_labels = ["Bx", "By", "Bz", "Magnitude"]
    B_RTN_labels = [L"B_R", L"B_T", L"B_N", L"|B\;|"]
    B_LMN_labels = [L"B_L", L"B_M", L"B_N"]
    B_XYZ_labels = [L"B_x", L"B_y", L"B_z", L"|B\;|"]
    n_ylabel = ulabel("n", "cm^-3")

    V_ylabel = ulabel("V", "km/s")
    V_labels = ["Vx", "Vy", "Vz", "Magnitude"]
    V_RTN_labels = [L"V_R", L"V_T", L"V_N", L"|V\;|"]
    V_LMN_labels = [L"V_L", L"V_M", L"V_N"]
    V_XYZ_labels = [L"V_x", L"V_y", L"V_z", L"|V\;|"]
    ΔV_ylabel = "ΔV (km/s)"

    T_ylabel = ulabel("T", "eV")
end
