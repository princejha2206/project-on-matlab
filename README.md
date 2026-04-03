companding (compressing + expanding) is a non-linear signal processing technique used in telephony PCM systems to improve the perceived audio quality at low signal amplitudes. Instead of uniformly quantising the raw signal, the signal is first compressed (mapping small amplitudes to a proportionally larger fraction of the quantiser range), quantised uniformly, then expanded back to the original scale at the receiver.

This project implements and compares the two internationally standardised companding laws: μ-Law (North America & Japan, ITU-T G.711 μ=255) and A-Law (Europe, ITU-T G.711 A=87.6) against plain uniform PCM.

