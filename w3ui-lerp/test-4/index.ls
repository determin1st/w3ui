"use strict"
# redsock color animation tests
do !->
    # declare
    duration = 4
    playState = -3
    CIE = do -> # {{{
        # constants
        CIE2000_G = Math.pow 25, 7
        CIE_e = 216 / 24389
        CIE_k = 24389 / 27
        CIE_ek = CIE_e * CIE_k
        oneThird = 1/3
        toRadian = Math.PI / 180
        toDegree = 180 / Math.PI
        # D65, White point
        Xr = 0.95047
        Yr = 1.00000
        Zr = 1.08883
        RGBtoHSL = ([R, G, B]) -> # {{{
            # normalize
            R = R / 255.0
            G = G / 255.0
            B = B / 255.0
            # determine initial factors
            max = Math.max R, G, B
            min = Math.min R, G, B
            dif = max - min
            sum = max + min
            # determine Lightness and Saturation
            L = sum / 2
            S = if L > 0.5
                then dif / (2 - sum)
                else dif / sum
            # determine Hue
            if dif < 0.000001
                ##
                H = S = 0
                ##
            else if max - R < 0.000001
                # R° / (360° / hex sides)
                if (H = (G - B) / dif) < 0
                    # hue > 180, full rotation 360/60
                    H = H + 6
                ##
            else if max - G < 0.000001
                # G° / (360° / hex sides)
                H = (B - R) / dif + 2
                ##
            else if max - B < 0.000001
                # B° / (360° / hex sides)
                H = (R - G) / dif + 4
            # scale values and finish
            return [
                H * 60
                S * 100
                L * 100
            ]
        # }}}
        RGBtoLUV = ([R, G, B]) -> # {{{
            # check
            if R == G == B == 0
                return [0, 0, 0]
            # normalize
            R = R / 255.0
            G = G / 255.0
            B = B / 255.0
            # inverse companding
            # as the color source is not a device, this step is not required
            # ...
            # convert to XYZ using sRGB matrix
            # all RGB colors in browser are specified in the sRGB color space
            X = R * 0.4124564 + G * 0.3575761 + B * 0.1804375
            Y = R * 0.2126729 + G * 0.7151522 + B * 0.0721750
            Z = R * 0.0193339 + G * 0.1191920 + B * 0.9503041
            # convert to LUV
            a = Y / Yr
            b = X + 15*Y + 3*Z
            c = Xr + 15*Yr + 3*Zr
            ##
            L = if a > CIE_e
                then 116 * (Math.pow a, oneThird) - 16
                else CIE_k * a
            ##
            U = (4*X / b) - (4*Xr / c)
            U = 13 * L * U
            ##
            V = (9*Y / b) - (9*Yr / c)
            V = 13 * L * V
            ###
            return [L, U, V]
        # }}}
        LUVtoRGB = (L, U, V) -> # {{{
            # convert to XYZ first
            ##
            Y = if L > CIE_ek
                then Math.pow ((L + 16) / 116), 3
                else L / CIE_k
            ##
            u0 = 4*Xr / (Xr + 15*Yr + 3*Zr)
            v0 = 9*Yr / (Xr + 15*Yr + 3*Zr)
            ##
            a = oneThird * ((52*L / (U + 13*L*u0)) - 1)
            b = -5*Y
            c = Y * ((39*L / (V + 13*L*v0)) - 5)
            ##
            X = (c - b) / (a + oneThird)
            Z = X * a + b
            # convert to RGB using sRGB reverse matrix
            R = 0 + X * 3.2404542 - Y * 1.5371385 - Z * 0.4985314
            G = 0 - X * 0.9692660 + Y * 1.8760108 + Z * 0.0415560
            B = 0 + X * 0.0556434 - Y * 0.2040259 + Z * 1.0572252
            R = 0 if R < 0
            G = 0 if G < 0
            B = 0 if B < 0
            # RGB companding (not required)
            # ...
            # done
            return [
                (R * 255) .|. 0
                (G * 255) .|. 0
                (B * 255) .|. 0
            ]
        # }}}
        RGBtoLAB = ([R, G, B]) -> # {{{
            # normalize
            R = R / 255.0
            G = G / 255.0
            B = B / 255.0
            # inverse companding
            # as the color source is not a device, this step is not required
            #R = if R > 0.04045
            #    then Math.pow ((R + 0.055) / 1.055), 2.4
            #    else R / 12.92
            #G = if G > 0.04045
            #    then Math.pow ((G + 0.055) / 1.055), 2.4
            #    else G / 12.92
            #B = if B > 0.04045
            #    then Math.pow ((B + 0.055) / 1.055), 2.4
            #    else B / 12.92
            # convert to XYZ using sRGB matrix
            # all RGB colors in browser are specified in the sRGB color space
            X = R * 0.4124564 + G * 0.3575761 + B * 0.1804375
            Y = R * 0.2126729 + G * 0.7151522 + B * 0.0721750
            Z = R * 0.0193339 + G * 0.1191920 + B * 0.9503041
            # convert to LAB
            # scale XYZ using reference white from CIE D65
            X = X / 0.95047
            Y = Y / 1.00000
            Z = Z / 1.08883
            # calculate
            X = if X > CIE_e
                then Math.pow X, oneThird
                else (CIE_k * X + 16) / 116
            Y = if Y > CIE_e
                then Math.pow Y, oneThird
                else (CIE_k * Y + 16) / 116
            Z = if Z > CIE_e
                then Math.pow Z, oneThird
                else (CIE_k * Z + 16) / 116
            # done
            return [
                116 * Y - 16
                500 * (X - Y)
                200 * (Y - Z)
            ]
        # }}}
        LABtoRGB = (L, A, B) -> # {{{
            # convert to XYZ
            #1
            Y = (L + 16) / 116
            Z = Y - B / 200
            X = A / 500 + Y
            #2
            Y = if L > CIE_ek
                then Math.pow ((L + 16) / 116), 3
                else L / CIE_k
            z3 = Math.pow Z, 3
            Z = if z3 > CIE_e
                then z3
                else (116 * Z - 16) / CIE_k
            x3 = Math.pow X, 3
            X = if x3 > CIE_e
                then x3
                else (116 * X - 16) / CIE_k
            # scale using reference white from CIE D65
            X = X * 0.95047
            Y = Y * 1.00000
            Z = Z * 1.08883
            # convert to RGB using sRGB matrix
            R = 0 + X * 3.2404542 - Y * 1.5371385 - Z * 0.4985314
            G = 0 - X * 0.9692660 + Y * 1.8760108 + Z * 0.0415560
            B = 0 + X * 0.0556434 - Y * 0.2040259 + Z * 1.0572252
            R = 0 if R < 0
            G = 0 if G < 0
            B = 0 if B < 0
            # RGB companding (not required)
            # ...
            # done
            return [
                (R * 255) .|. 0
                (G * 255) .|. 0
                (B * 255) .|. 0
            ]
        # }}}
        deltaE = (c1, c2) -> # CIE 2000 {{{
            ##
            # http://www2.ece.rochester.edu/~gsharma/ciede2000/
            # http://www2.ece.rochester.edu/~gsharma/ciede2000/ciede2000noteCRNA.pdf
            # http://www.brucelindbloom.com
            ##
            # determine L', dL
            L = (c1.0 + c2.0) / 2
            dL = c2.0 - c1.0
            # determine C
            C1 = Math.sqrt ((Math.pow c1.1, 2) + (Math.pow c1.2, 2))
            C2 = Math.sqrt ((Math.pow c2.1, 2) + (Math.pow c2.2, 2))
            C = (C1 + C2) / 2
            # determine G
            G = Math.pow C, 7
            G = Math.sqrt (G / (G + CIE2000_G))
            G = 0.5 * (1 - G)
            # determine a1, a2, C', dC'
            a1 = c1.1 * (1 + G)
            a2 = c2.1 * (1 + G)
            C1a = Math.sqrt ((Math.pow a1, 2) + (Math.pow c1.2, 2))
            C2a = Math.sqrt ((Math.pow a2, 2) + (Math.pow c2.2, 2))
            C12 = Math.abs (C1a * C2a)
            Ca = (C1a + C2a) / 2
            dC = C2a - C1a
            # determine H, dH
            if (h1 = (Math.atan2 c1.2, a1) * toDegree) < 0
                h1 = h1 + 360
            if (h2 = (Math.atan2 c2.2, a2) * toDegree) < 0
                h2 = h2 + 360
            if C12 > 0.000001
                dH = h2 - h1
                H = Math.abs dH
                if H > 180
                    H = (h1 + h2 + 360) / 2
                    dH = if h2 > h1
                        then dH - 360
                        else dH + 360
                else
                    H = (h1 + h2) / 2
                dH = dH * toRadian / 2
                dH = 2 * (Math.sqrt C12) * (Math.sin dH)
            else
                H = h1 + h2
                dH = 0
            # determine T
            h1 = (H - 30) * toRadian
            h2 = (2 * H) * toRadian
            T = 1 - 0.17 * (Math.cos h1) + 0.24 * (Math.cos h2)
            h1 = (3 * H + 6) * toRadian
            h2 = (4 * H - 63) * toRadian
            T = T + 0.32 * (Math.cos h1) - 0.20 * (Math.cos h2)
            # determine S (L,C,H)
            sL = Math.pow (L - 50), 2
            sL = 1 + 0.015 * sL / (Math.sqrt (20 + sL))
            sC = 1 + 0.045 * C
            sH = 1 + 0.015 * C * T
            # determine R
            H = Math.pow ((H - 275) / 25), 2
            H = 60 * (Math.exp -H)
            if H > 0.0001 and H < 359.9999
                G = Math.pow Ca, 7
                G = 2 * Math.sqrt (G / (G + CIE2000_G))
                R = -G * Math.sin (H * toRadian)
            else
                R = 0
            # compute distance
            L = dL / sL
            C = dC / sC
            H = dH / sH
            return L*L + C*C + H*H + R*C*H
        # }}}
        deltaE_CMC = (LAB1, LAB2, lc = [1, 1]) -> # CMC(l:c) {{{
            ##
            # http://www.brucelindbloom.com/index.html?Eqn_DeltaE_CMC.html
            # The color difference method of the Color Measurement Committee
            # (the CMC) is a model using two parameters l and c,
            # typically expressed as CMC(l:c). Commonly used values for
            # acceptability are CMC(2:1) and for perceptibility are CMC(1:1).
            ##
            # determine delta L
            dL = LAB1.0 - LAB2.0
            # determine delta C
            C1 = Math.sqrt ((Math.pow LAB1.1, 2) + (Math.pow LAB1.2, 2))
            C2 = Math.sqrt ((Math.pow LAB2.1, 2) + (Math.pow LAB2.2, 2))
            dC = C1 - C2
            # determine delta H
            dA = Math.pow (LAB1.1 - LAB2.1), 2
            dB = Math.pow (LAB1.2 - LAB2.2), 2
            dH = dA + dB - (Math.pow dC, 2)
            # determine L divider
            sL = if LAB1.0 < 16
                then 0.511
                else 0.040975 * LAB1.0 / (1 + 0.01765 * LAB1.0)
            # determine C divider
            sC = (0.0638 * C1 / (1 + 0.0131 * C1)) + 0.638
            # determine H1 divider
            H = (Math.atan2 LAB1.2, LAB1.1) * toDegree
            H = H + 360 if H < 0
            if H < 164 or H > 345
                H = (H + 35) * toRadian
                H = 0.36 + 0.4 * Math.abs Math.cos H
            else
                H = (H + 168) * toRadian
                H = 0.56 + 0.2 * Math.abs Math.cos H
            F = Math.pow C1, 4
            F = Math.sqrt (F / (F + 1900))
            sH = sC * (F * H + 1 - F)
            sH = Math.pow sH, 2
            # divide
            dL = dL / sL * lc.0
            dC = dC / sC * lc.1
            dH = dH / (Math.pow sH, 2)
            # compute distance^2
            return (Math.pow dL, 2) + (Math.pow dC, 2) + dH
        # }}}
        approxLABRange = (c1, c2, deep = 0) -> # {{{
            # determine color distance^2
            if (D = deltaE c1, c2) < 4
                # approximation is not necessary,
                # colors are very close
                return null
            # prepare
            c1.pos = if 'pos' of c1
                then c1.pos
                else 0
            c2.pos = if 'pos' of c2
                then c2.pos
                else 1
            # approximate
            #a = [c1]
            #for b in [0.25, 0.3, 0.35, 0.4]
            #    d1 = D * b
            #    d2 = D - d1
            #    c = approxLABPoint c1, c2, d1, d2
            #    c.pos = c1.pos + (c2.pos - c1.pos) * b
            #    a.push c
            #a.push c2
            ###
            d1 = D * 0.5
            d2 = D - d1
            c = approxLABPoint c1, c2, d1, d2
            c.pos = c1.pos + (c2.pos - c1.pos) * 0.5
            if deep
                # approximate two more ranges
                a = approxLABRange c1, c, deep - 1
                b = approxLABRange c, c2, deep - 1
                # compose final result
                if a and b
                    # approximate connection between them
                    #c = approxLABRange a[* - 2], b.1, 0, true
                    #c = c.1
                    # join together
                    a.splice -1, 1, c
                    a = a ++ (b.slice 1)
                else if a
                    # append end point
                    a.push c2
                else if b
                    # insert start point
                    b.unshift c1
                    a = b
                else
                    # single point
                    a = [c1, c, c2]
                # select last approximated point
                c = a[* - 2]
            else
                # single point
                a = [c1, c, c2]
            # determine final delta
            c2.delta =
                c2.0 - c.0
                c2.1 - c.1
                c2.2 - c.2
            # done
            a.distance = D
            return a
        # }}}
        approxLABPoint = (c1, c2, D1, D2) -> # {{{
            # prepare
            # determine initial color
            x =
                c2.0 - c1.0
                c2.1 - c1.1
                c2.2 - c1.2
            found =
                c1.0 + x.0 * 0.5
                c1.1 + x.1 * 0.5
                c1.2 + x.2 * 0.5
            temp = found.slice!
            approx = found.slice!
            # determine color factor range
            x = [[128, 100], [0, 256], [0, 256]]
            # determine color factor indexes: 0=L, 1=a, 2=b
            i1 = 0
            i2 = 1
            i3 = 2
            # determine search precision limit
            limit1 = 0.01
            limit2 = 0.01
            limit3 = 0.01
            # do triple binary searching
            # {{{
            range1 = [0, 1]
            direction1 = true
            delta1 = [D1+D2, D1, D2]
            found1 = 0
            while (a = range1.1 - range1.0) > limit1
                # determine first factor
                #temp[i1] = c1[i1] + x[i1] * (range1.0 + a * 0.5)
                temp[i1] = x[i1].0 + x[i1].1 * (range1.0 + a * 0.5) - 128
                # 2
                range2 = [0, 1]
                direction2 = true
                delta2 = delta1.slice!
                found2 = 0
                while (b = range2.1 - range2.0) > limit2
                    # determine second factor
                    #temp[i2] = c1[i2] + x[i2] * (range2.0 + b * 0.5)
                    temp[i2] = x[i2].0 + x[i2].1 * (range2.0 + b * 0.5) - 128
                    # 3
                    range3 = [0, 1]
                    direction3 = true
                    delta3 = delta2.slice!
                    found3 = 0
                    while (c = range3.1 - range3.0) > limit3
                        # determine third factor
                        #temp[i3] = c1[i3] + x[i3] * (range3.0 + c * 0.5)
                        temp[i3] = x[i3].0 + x[i3].1 * (range3.0 + c * 0.5) - 128
                        # calculate distance deltas
                        d1 = Math.abs (D1 - (deltaE c1, temp))
                        d2 = Math.abs (D2 - (deltaE temp, c2))
                        d0 = d1 + d2
                        # CHECK it
                        #if d1 <= delta3.1 and d2 <= delta3.2 and d0 < delta3.0
                        if d0 <= delta3.0
                            # direction is correct
                            ++found3
                            approx[i3] = temp[i3]
                            delta3.0 = d0
                            delta3.1 = d1
                            delta3.2 = d2
                            shift = c * 0.25
                        else
                            # direction is wrong
                            direction3 = !direction3
                            shift = c * 0.5
                        # reduce the range
                        if direction3
                            range3.0 = range3.0 + shift
                        else
                            range3.1 = range3.1 - shift
                    # check result 3
                    if found3
                        # direction is correct
                        ++found2
                        approx[i2] = temp[i2]
                        delta2 <<< delta3
                        shift = b * 0.25
                    else
                        # direction is wrong
                        direction2 = !direction2
                        shift = b * 0.5
                    # reduce the range
                    if direction2
                        range2.0 = range2.0 + shift
                    else
                        range2.1 = range2.1 - shift
                # check result 2
                if found2 and delta2.1 < delta1.1 and delta2.2 < delta1.2
                    # direction is correct
                    ++found1
                    approx[i1] = temp[i1]
                    found = approx.slice!
                    delta1 <<< delta2
                    shift = a * 0.25
                else
                    # direction is wrong
                    direction1 = !direction1
                    shift = a * 0.5
                # reduce the range
                if direction2
                    range1.0 = range1.0 + shift
                else
                    range1.1 = range1.1 - shift
            # }}}
            # determine color delta
            found.delta =
                found.0 - c1.0
                found.1 - c1.1
                found.2 - c1.2
            # done
            return found
        # }}}
        approxLAB = (range, scale) -> # Approximated LAB color {{{
            # determine current position and
            # get colors
            if scale <= 0
                c1 = range.0
                c2 = range.1
            else if scale >= 1
                c1 = range[* - 2]
                c2 = range[* - 1]
            else
                for c,b in a when scale <= c.pos
                    c1 = range[b - 1]
                    c2 = c
                    break
            # re-calculate the scale
            scale = (scale - c1.pos) / (c2.pos - c1.pos)
            # calculate current
            d = c2.delta
            R = c1.0 + d.0 * scale
            G = c1.1 + d.1 * scale
            B = c1.2 + d.2 * scale
            # convert LAB to RGB
            [R, G, B] = LABtoRGB R, G, B
            # done
            return 'rgb('+R+','+G+','+B+')'
        # }}}
        checkHSL = (c1, c2) -> # {{{
            # convert from RGB
            c1 = RGBtoHSL c1
            c2 = RGBtoHSL c2
            HSL = [c1, c2]
            # determine Hue delta
            a = c1.0
            b = c2.0
            if (a <= 180 and b <= 180) or (a > 180 and b > 180) or
                (a <= 270 and b <= 270 and a > 90 and b > 90)
                # same or close sectors
                c = b - a
            else if (a <= 90 and b > 270) or (a > 270 and b <= 90)
                # close sectors [0..90] && [270..360]
                if b > a
                    # clockwise
                    c = b - 360 - a
                else
                    # counter-clockwise
                    c = b + 360 - a
            else
                # opposite sectors
                # calculate two possible distances
                d1 = b - a
                d2 = if b > a
                    then b - 360 - a
                    else b + 360 - a
                # select shortest
                c = if (Math.abs d1) < (Math.abs d2)
                    then d1
                    else d2
            # store HSL color delta
            HSL.delta = [
                c
                c2.1 - c1.1
                c2.2 - c1.2
            ]
            return HSL
        # }}}
        testDeltaE = !-> # {{{
            # define test data
            s1 =
                [50.0000, 2.6772, -79.7751] # 1
                [50.0000, 3.1571, -77.2803]
                [50.0000, 2.8361, -74.0200] # 3
                [50.0000, -1.3802, -84.2814] # 4
                [50.0000, -1.1848, -84.8006]
                [50.0000, -0.9009, -85.5211] # 6
                [50.0000, 0.0000, 0.0000] # 7
                [50.0000, -1.0000, 2.0000]
                [50.0000, 2.4900, -0.0010]
                [50.0000, 2.4900, -0.0010]
                [50.0000, 2.4900, -0.0010]
                [50.0000, 2.4900, -0.0010]
                [50.0000, -0.0010, 2.4900]
                [50.0000, -0.0010, 2.4900]
                [50.0000, -0.0010, 2.4900]
                [50.0000, 2.5000, 0.0000] # 16
                [50.0000, 2.5000, 0.0000] # 17
                [50.0000, 2.5000, 0.0000]
                [50.0000, 2.5000, 0.0000]
                [50.0000, 2.5000, 0.0000] # 20
                [50.0000, 2.5000, 0.0000] # 21
                [50.0000, 2.5000, 0.0000]
                [50.0000, 2.5000, 0.0000]
                [50.0000, 2.5000, 0.0000]
                [60.2574, -34.0099, 36.2677]
                [63.0109, -31.0961, -5.8663]
                [61.2901, 3.7196, -5.3901]
                [35.0831, -44.1164, 3.7933]
                [22.7233, 20.0904, -46.6940]
                [36.4612, 47.8580, 18.3852]
                [90.8027, -2.0831, 1.4410]
                [90.9257, -0.5406, -0.9208]
                [6.7747, -0.2908, -2.4247]
                [2.0776, 0.0795, -1.1350] # 34
            s2 =
                [50.0000, 0.0000, -82.7485] # 1
                [50.0000, 0.0000, -82.7485]
                [50.0000, 0.0000, -82.7485] # 3
                [50.0000, 0.0000, -82.7485] # 4
                [50.0000, 0.0000, -82.7485]
                [50.0000, 0.0000, -82.7485] # 6
                [50.0000, -1.0000, 2.0000] # 7
                [50.0000, 0.0000, 0.0000]
                [50.0000, -2.4900, 0.0009]
                [50.0000, -2.4900, 0.0010]
                [50.0000, -2.4900, 0.0011]
                [50.0000, -2.4900, 0.0012]
                [50.0000, 0.0009, -2.4900]
                [50.0000, 0.0010, -2.4900]
                [50.0000, 0.0011, -2.4900]
                [50.0000, 0.0000, -2.5000] # 16
                [73.0000, 25.0000, -18.0000] # 17
                [61.0000, -5.0000, 29.0000]
                [56.0000, -27.0000, -3.0000]
                [58.0000, 24.0000, 15.0000] # 20
                [50.0000, 3.1736, 0.5854] # 21
                [50.0000, 3.2972, 0.0000]
                [50.0000, 1.8634, 0.5757]
                [50.0000, 3.2592, 0.3350]
                [60.4626, -34.1751, 39.4387]
                [62.8187, -29.7946, -4.0864]
                [61.4292, 2.2480, -4.9620]
                [35.0232, -40.0716, 1.5901]
                [23.0331, 14.9730, -42.5619]
                [36.2715, 50.5065, 21.2231]
                [91.1528, -1.6435, 0.0447]
                [88.6381, -0.8985, -0.7239]
                [5.8714, -0.0985, -2.2286]
                [0.9033, -0.0636, -0.5514] # 34
            # define results
            s3 =
                2.0425 # 1
                2.8615
                3.4412 # 3
                1.0000 # 4
                1.0000
                1.0000 # 6
                2.3669 # 7
                2.3669
                7.1792
                7.1792
                7.2195
                7.2195
                4.8045
                4.8045
                4.7461
                4.3065 # 16
                27.1492 # 17
                22.8977
                31.9030
                19.4535 # 20
                1.0000 # 21
                1.0000
                1.0000
                1.0000
                1.2644
                1.2630
                1.8731
                1.8645
                2.0373
                1.4146
                1.4441
                1.5381
                0.6377
                0.9082 # 34
            # iterate and test
            n = 0
            for x1,index in s1
                # get second color
                x2 = s2[index]
                # get deltas
                dX1 = Math.sqrt (deltaE x1, x2)
                dX2 = Math.sqrt (deltaE x2, x1)
                if (Math.abs (dX1 - dX2)) > 0.0001 or (Math.abs (dX1 - s3[index])) > 0.0001
                    n++
                    console.log 'deltaE #'+(index + 1)+': '+dX1+' = '+dX2+' = '+s3[index]+' (c1->c2, c2->c1, result)'
            # done
            console.log 'Test complete. ('+n+' possible problems)'
        # }}}
        return {
            RGBtoHSL
            RGBtoLUV
            LUVtoRGB
            RGBtoLAB
            LABtoRGB
            deltaE
            approxLAB
            testDeltaE
        }
    # }}}
    nodeMap = # {{{
        ui: document.querySelectorAll '#ui' .0
        input: document.querySelectorAll '.ctl input'
        progress: document.querySelectorAll '.ctl .progress' .0
        forward: document.querySelectorAll '.box .start' .0
        backward: document.querySelectorAll '.box .end' .0
        red: document.querySelectorAll '.current .red' .0
        green: document.querySelectorAll '.current .green' .0
        presetBack: document.querySelectorAll '.preset .back div'
        presetFront: document.querySelectorAll '.preset .front .item'
        presetColor1: document.querySelectorAll '.preset .front .item .start'
        presetColor2: document.querySelectorAll '.preset .front .item .end'
        graph: [...(document.querySelectorAll '.graph')]
        opt: document.querySelectorAll '.rgb2option' .0
    # }}}
    playRed = do -> # {{{
        parseRGBA = do -> # {{{
            expRGBA = /(\d+),\s*(\d+),\s*(\d+)(,\s*(\d*(\.\d+)?))?/
            return (v) ->
                # use regular expression for extraction
                if not (v = v.match expRGBA)
                    return null
                # cast RGB to numbers
                v.1 = parseFloat v.1
                v.2 = parseFloat v.2
                v.3 = parseFloat v.3
                # cast Alpha
                v.4 = if v.5
                    then parseFloat v.5
                    else 1
                # done
                # truncate result
                return v.slice 1, 5
        # }}}
        onUpdate = (forward) -> # {{{
            return !->
                # set current
                #a = nodeMap.red
                #b = a._redsock.style.backgroundColor.currentHSL
                #a.innerHTML = 'hsl('+b.0+', '+b.1+'%, '+b.2+'%, '+b.3+')'
                # set progress
                scale = 100 * @scale
                a = nodeMap.progress
                b = Math.round scale
                b = 100 - b if not forward
                a.innerHTML = b+'%'
                # update graphs
                RGBx = @tween.0.css.backgroundColor
                if @scale == 0
                    # reset
                    # {{{
                    for c,d of charts
                        for d in d.data
                            d.x.length = 0
                            d.y.length = 0
                    ##
                    a = charts.distance.data.2
                    a.x.push 0
                    a.y.push 0
                    #a.y.push RGBx.distance
                    # }}}
                else if @scale == 1
                    # draw
                    # {{{
                    # distance
                    # add start/end points
                    d = charts.distance.data.3
                    d.x.push 0
                    d.y.push 0
                    d.x.push 100
                    c1 = CIE.RGBtoLAB RGBx.0
                    c2 = CIE.RGBtoLAB RGBx.1
                    d.y.push (CIE.deltaE c1, c2)
                    Plotly.newPlot nodeMap.graph.0, charts.distance
                    # RGB curves
                    Plotly.newPlot nodeMap.graph.1, charts.R
                    Plotly.newPlot nodeMap.graph.2, charts.G
                    Plotly.newPlot nodeMap.graph.3, charts.B
                    # reset state
                    playState := if playState < 0
                        then -3
                        else  3
                    # }}}
                else
                    # collect
                    # {{{
                    # get previous scale point
                    b = charts.R.data.0.x
                    b = if b.length
                        then b[b.length - 1]
                        else 0
                    # record only reasonable changes ~1% or more
                    if scale - b > 0.99
                        # determine current RGB values
                        RGB1 = parseRGBA nodeMap.red._redsock.cStyle.backgroundColor
                        RGB2 = parseRGBA nodeMap.green._style.backgroundColor
                        # determine current HSL values
                        #a = CIE.RGBtoHSL RGB1
                        #b = CIE.RGBtoHSL RGB2
                        a = RGB1
                        b = RGB2
                        # store
                        d = charts.R.data
                        d.0.y.push a.0
                        d.1.y.push b.0
                        d.0.x.push scale
                        d.1.x.push scale
                        d = charts.G.data
                        d.0.y.push a.1
                        d.1.y.push b.1
                        d.0.x.push scale
                        d.1.x.push scale
                        d = charts.B.data
                        d.0.y.push a.2
                        d.1.y.push b.2
                        d.0.x.push scale
                        d.1.x.push scale
                        ##
                        # determine current LAB values
                        a = CIE.RGBtoLAB RGB1
                        b = CIE.RGBtoLAB RGB2
                        c = CIE.RGBtoLAB RGBx.0
                        d = CIE.RGBtoLAB RGBx.1
                        # determine color distances
                        a = CIE.deltaE a, c
                        b = CIE.deltaE b, c
                        c = CIE.deltaE c, d
                        c = c * @scale
                        # store
                        d = charts.distance.data
                        d.0.y.push a
                        d.1.y.push b
                        d.2.y.push c
                        d.0.x.push scale
                        d.1.x.push scale
                        d.2.x.push scale
                    # }}}
        # }}}
        play = -> # {{{
            # prepare
            switch playState
            | -2 => a0.pause!
            | -1 => a0.play!
            |  1 => a1.play!
            |  2 => a1.pause!
        # }}}
        # {{{
        a1 = {
            target: [
                nodeMap.red
                nodeMap.forward
                nodeMap.backward
            ]
            duration: duration
            className: '+tested'
            onUpdate: onUpdate true
        }
        a0 = {
            target: [
                nodeMap.red
                nodeMap.forward
                nodeMap.backward
            ]
            duration: duration
            className: '-tested'
            onUpdate: onUpdate false
        }
        a0 = redsock a0
        a1 = redsock a1
        # }}}
        return play
    # }}}
    playGreen = do -> # {{{
        # define
        onUpdate = !-> # {{{
            # set current
            #a = nodeMap.green
            #a.innerHTML = a._style.backgroundColor
        # }}}
        play = (oldState) !-> # {{{
            switch playState
            | -2 => a0.pause!
            | -1 =>
                if oldState == -2
                    a0.play!
                else
                    a0.invalidate!play 0
            |  1 =>
                if oldState == 2
                    a1.play!
                else
                    a1.invalidate!play 0
            |  2 => a1.pause!
        # }}}
        # initialize
        # {{{
        a1 = {
            className: '+=tested'
            ease: Power0.easeIn
            onUpdate: onUpdate
            paused: true
        }
        a0 = {
            className: '-=tested'
            ease: Power0.easeIn
            onUpdate: onUpdate
            paused: true
        }
        # create
        node = nodeMap.green
        a0 = new TweenLite node, duration, a0
        a1 = new TweenLite node, duration, a1
        # get computed style
        if not node._style
            node._style = window.getComputedStyle node
        # }}}
        return play
    # }}}
    playAll = !-> # {{{
        a = playState
        switch playState
        | -3 => playState :=  1
        | -2 => playState := -1
        | -1 => playState := -2
        |  1 => playState :=  2
        |  2 => playState :=  1
        |  3 => playState := -1
        playRed!
        playGreen a
    # }}}
    charts = # {{{
        R:
            data:
                {
                    x: []
                    y: []
                    type: 'lines'
                    showlegend: false
                    line:
                        color: 'red'
                }
                {
                    x: []
                    y: []
                    type: 'lines'
                    showlegend: false
                    line:
                        color: 'green'
                }
        G:
            data:
                {
                    x: []
                    y: []
                    type: 'lines'
                    showlegend: false
                    line:
                        color: 'red'
                }
                {
                    x: []
                    y: []
                    type: 'lines'
                    showlegend: false
                    line:
                        color: 'green'
                }
        B:
            data:
                {
                    x: []
                    y: []
                    type: 'lines'
                    showlegend: false
                    line:
                        color: 'red'
                }
                {
                    x: []
                    y: []
                    type: 'lines'
                    showlegend: false
                    line:
                        color: 'green'
                }
        distance:
            xaxis:
                range: [0, 100]
            yaxis:
                range: [0, 0]
            data:
                {
                    x: []
                    y: []
                    mode: 'lines'
                    type: 'scatter'
                    name: 'redsock'
                    line:
                        color: 'red'
                }
                {
                    x: []
                    y: []
                    mode: 'lines'
                    type: 'scatter'
                    name: 'greensock'
                    line:
                        color: 'green'
                }
                {
                    x: []
                    y: []
                    mode: 'lines'
                    type: 'scatter'
                    name: 'ideal(?)'
                    line:
                        color: 'gray'
                        width: 0.5
                }
                {
                    x: []
                    y: []
                    mode: 'markers'
                    type: 'scatter'
                    name: 'start/end'
                    showlegend: false
                    marker:
                        color: 'gray'
                        width: 6
                }
    # }}}
    selectColors = (index) !-> # {{{
        # get nodes
        n1 = nodeMap.presetColor1[index]
        n2 = nodeMap.presetColor2[index]
        # get their colors
        c1 = n1.style.getPropertyValue '--start-color'
        c2 = n2.style.getPropertyValue '--end-color'
        # set css-vars
        nodeMap.ui.style.setProperty '--start-color', c1
        nodeMap.ui.style.setProperty '--end-color', c2
        # parse
        exp = /(\d+),\s*(\d+)%,\s(\d+)%(,\s*([0-9.]+))?/
        c1 = c1.match exp
        c1.4 = if c1.5 == undefined
            then 1
            else c1.5
        c2 = c2.match exp
        c2.4 = if c2.5 == undefined
            then 1
            else c2.5
        c1 = c1.slice 1, 5
        c2 = c2.slice 1, 5
        # set inputs
        nodeMap.input.0.value = c1.0 + ', ' + c1.1 + '%, ' + c1.2 + '%, ' + c1.3
        nodeMap.input.1.value = c2.0 + ', ' + c2.1 + '%, ' + c2.2 + '%, ' + c2.3
        # clear currents
        nodeMap.red.innerHTML = ''
        nodeMap.green.innerHTML = ''
    # }}}
    # initialize
    do !->
        nodeMap.forward.addEventListener 'click', playAll
        nodeMap.backward.addEventListener 'click', playAll
        ##
        for a in nodeMap.presetBack
            a.addEventListener 'click', !->
                nodeMap.ui.style.setProperty '--back-color', @className
        ##
        selectColors 0
        for a,b in nodeMap.presetFront
            a.addEventListener 'click', selectColors.bind @, b
        ##
        nodeMap.opt.addEventListener 'click', !->
            redsock.enableRGB2 = nodeMap.opt.checked
    ##


