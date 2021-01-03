globals [
  arbres-initiaux    ;; avec combien d'arbres nous commençons (arbres verts)
  arbres-brules    ;; combien d'arbres ont brulés
  positionx ;; permet de retenir la coordonnée x d'un feu
  positiony ;; permet de retenir la coordonnée y d'un feu
  tombe ;; de quel côté un arbre va tomber
  aleatoire ;; nombres aléatoires
]

;;définition des tortues
breed [feux feu]    ;; tortues rouges: le feu qui se répend
breed [eaux eau] ;; tortues bleues: l'eau
breed [coupe-feux coupe-feu]

;;Initialisation
to setup
  clear-all
  set-default-shape turtles "tree"

  initialise-rivieres
  if coupes-feux
  [
    initialise-coupe-feux
  ]

  initialise-arbres

  initialise-feux

  set arbres-initiaux count patches with [pcolor = green - 3.5] + 1
  set arbres-brules 0 ;; on initialise arbres-brules à 0

  reset-ticks  ;;on met l'horloge à 0
end

;;procédure qui colore les patches en vert pour représenter les arbres
to initialise-arbres
  ask patches with [(random-float 100) < densité]
    [ if pcolor != blue and pcolor != brown;;on ne met pas d'arbre lorsqu'il y a de l'eau ou un coupe-feu
      [set pcolor green - 3.5
      ]
  ]
end

;;procédure qui créé les turtles feux là où il y a un départ de feux (localisation aléatoire)
to initialise-feux
  let i 0
  while [i < foyer-de-feu]
  [
     ask one-of patches with [pcolor = green - 3.5]
     [
            sprout-feux 1
            [ set color red ]
            set i i + 1
     ]
  ]
end

;;procédure qui permet de représenter les coupe-feux
to initialise-coupe-feux

  if largeur-parcelles != 0
  [
    ask patches with [ pxcor mod largeur-parcelles = 0 and pycor = min-pycor]
    [
      sprout-coupe-feux 1 [set pcolor brown ]
    ]

    let i 0

    while [i < world-height]
    [
      ask coupe-feux
      [
        ask patches in-radius (largeur-coupe-feu / 2)
        [
          set pcolor brown
        ]
        facexy xcor (ycor + 1)
        fd 1
      ]
      set i i + 1
    ]
    ask coupe-feux
    [
      die
    ]
  ]
  if hauteur-parcelles != 0
  [
    ask patches with [ pycor mod hauteur-parcelles = 0 and pxcor = min-pxcor]
    [
      sprout-coupe-feux 1 [set pcolor brown]
    ]
    let i 0
    while [i < world-height]
    [
      ask coupe-feux
      [
        ask patches in-radius (largeur-coupe-feu / 2)
        [
          set pcolor brown
        ]
        facexy xcor + 1 ycor
        fd 1
      ]
      set i i + 1
    ]
    ask coupe-feux
    [
      die
    ]
  ]
end

;;procédure qui créé la rivière
to initialise-rivieres
  if largeur-rivières != 0 [
    ask n-of 1 patches
    [ sprout-eaux 1 [set pcolor blue]]

    let i 0
    while [ i < (max-pycor)]
    [
      ask eaux
      [
        ifelse not can-move? 1 [die]
        [
          fd 1
          set pcolor blue
          ifelse (i mod 4  = 0)
          [
            let angle-min random 60
            set angle-min angle-min * -1
            let angle-max random 60
            ifelse (random 100) < 50
            [
              rt angle-min
            ]
            [
              rt angle-max
            ]
            fd 1
          ]
          [
            fd 1
            set pcolor blue
            fd 1
          ]
          let radius random largeur-rivières
          set radius radius + 1
          ask patches in-radius radius
          [
            set pcolor blue
          ]
        ]
      ]
      set i i + 1
    ]
  ]
end

;; Lancement du programme
to go
 ask feux
   [
    set positionx pxcor ;;on enregistre la position du feu
    set positiony pycor
    ask neighbors4 with [ pcolor = green - 3.5] ;;regarde les 4 voisins de l'arbre en feu et si ce sont des arbre, on les enflamme
    [enflammer]

    ;;le vent propage le feu un peu plus loin selon son intensité :
    vent-enflamme intensité-vent sens-vent
    ;; un arbre qui tombe propage le feu plus loin selon sa taille :
      arbre-tombe
      die]
  tick ;; on avance l'horloge d'un.
end

;;procédure qui permet de créer un turtle feu sur un arbre qui se fait enflammer
to enflammer
  if random 100 > humidité
  [
    sprout-feux 1
    [ set color red ]
    set pcolor gray
    set arbres-brules arbres-brules + 1
  ]
end

;;procédure qui réalise la propagation du feu de forêt avec l'effet du vent. Arguments: l'intensité du vent et son orientation
to vent-enflamme [portée sens]
  if portée != 0 [
    let l intensité-vent / 3 ;;on décide que le vent propage le feux à ue distance en mètres égale à son intensité divisé par 3.

   ;; tous les arbres dans le rayon l de l'arbre enflammé d'origine prennent feu (dansle sens dans lequel le vent souffle)
    if sens-vent = "Nord-Sud"[
      ask patches in-radius l with [ (pcolor = green - 3.5) and (pycor <= positiony) ]
      [enflammer]]

    if sens-vent = "Sud-Nord"[
      ask patches in-radius l with [ (pcolor = green - 3.5) and (pycor >= positiony) ]
      [enflammer]]
    if sens-vent = "Est-Ouest"[
      ask patches in-radius l with [ (pcolor = green - 3.5) and (pxcor <= positionx) ]
      [enflammer]]
    if sens-vent = "Ouest-Est"[
      ask patches in-radius l with [ (pcolor = green - 3.5) and (pxcor >= positionx) ]
      [enflammer]]
  ]
end

;;procédure qui réalise la propagation du feu de forêt avec l'effet d'un arbre qui tombe suite à son embrasement
to arbre-tombe
  if random 1000 = 0  ;;1 risque sur 1000 que cela arrive
  [
    if intensité-vent <= 5 [    ;; si l'intensité du vent est faible on considère que cela n'a pas d'incidence sur le côté duquel tombe l'arbre
      set aleatoire random 4
      if aleatoire = 0[ set tombe "Nord-Sud"]
      if aleatoire = 1[ set tombe "Sud-Nord"]
      if aleatoire = 2[ set tombe "Est-Ouest"]
      if aleatoire = 3[ set tombe "Ouest-Est"]
    ]
    if intensité-vent > 5 [       ;; On considère que si le vent souffle à plus de 5 km/h, son sens a une incidence sur le côté duquel tombe l'arbre
      if sens-vent = "Nord-Sud"
      [choix-côté-tombe "Nord-Sud" "Sud-Nord" "Est-Ouest" "Ouest-Est"]
      if sens-vent = "Sud-Nord"
      [choix-côté-tombe "Sud-Nord" "Nord-Sud" "Est-Ouest" "Ouest-Est"]
      if sens-vent = "Est-Ouest"
      [choix-côté-tombe "Est-Ouest" "Nord-Sud" "Sud-Nord" "Ouest-Est"]
      if sens-vent = "Ouest-Est"
      [choix-côté-tombe "Ouest-Est" "Sud-Nord" "Nord-Sud" "Est-Ouest"]
    ]
    arbre-enflamme taille-arbre tombe  ;;on appelle la procédure qui permet d'embraser ce que l'arbre touche en tombant. taille-arbre=portée, tombe = sens
  ]


end

;; Procédure qui permet de dire de quel côté tombe un arbre. Arguments: le sens du vent qui souffle, puis les autres sens dans lesquels le vent ne souffle pas au cours de la simulation
to choix-côté-tombe [vent sens1 sens2 sens3]
  set aleatoire random 2
  if aleatoire = 0[set tombe vent]     ;;l'arbre a 1 chance sur 2 de tomber dans le sens dans lequel le vent souffle
  if aleatoire = 1 [                   ;; sinon il a autant de chance de tomber dans un des 3 sens restants.
    set aleatoire random 3
    if aleatoire = 0 [set tombe sens1]
    if aleatoire = 1 [set tombe sens2]
    if aleatoire = 2 [set tombe sens3]
  ]
end

;; Procédure qui réalise la propagation du feu de forêt avec l'effet d'un arbre qui tombe. Arguments: la taille de l'arbre et le côté où il tombe
to arbre-enflamme [portée sens]
 let longueur 0
  if portée != 0 [
   set longueur portée
    if sens = "Nord-Sud"
  [
    let i 1
    while [ i < longueur ]  ;;cette boucle permet de passer en gris tous les arbres touchés par l'arbre qui tombe (en ligne droite)
    [
    ask patches with [ (pcolor = green - 3.5) and pxcor = positionx and pycor = positiony - i]
       [set pcolor gray  set arbres-brules arbres-brules + 1]
      set i i + 1
    ]
      if i = longueur[
        ask patches with [ (pcolor = green - 3.5) and pxcor = positionx and pycor = positiony - i]
        [ enflammer]
        ;; le dernier arbre touché s'enflamme et peut donc continuer à propager le feu.
      ]
  ]
    ;; la même chose est réalisée quelque soit le sens dans lequel est tombé l'arbre
 if sens = "Sud-Nord"[
    let i 1
    while [ i < longueur ]
    [
     ask patches with [(pcolor = green - 3.5) and pxcor = positionx and pycor = positiony + i]
      [set pcolor gray  set arbres-brules arbres-brules + 1]
      set i i + 1
    ]
      if i = longueur[
        ask patches with [(pcolor = green - 3.5) and pxcor = positionx and pycor = positiony + i]
        [ enflammer]
      ]
  ]
 if sens = "Est-Ouest"[
    let i 1
    while [ i < longueur ]
    [
    ask patches with [(pcolor = green - 3.5) and pxcor = positionx - i and pycor = positiony]
      [set pcolor gray  set arbres-brules arbres-brules + 1]
      set i i + 1
    ]
      if i = longueur[
        ask patches with [(pcolor = green - 3.5) and pxcor = positionx - i and pycor = positiony]
        [ enflammer]
      ]
  ]
 if sens = "Ouest-Est"[
    let i 1
    while [ i < longueur ]
    [
    ask patches with [(pcolor = green - 3.5) and pxcor = positionx + i and pycor = positiony]
      [set pcolor gray  set arbres-brules arbres-brules + 1]
        set i i + 1
    ]

      if i = longueur[
        ask patches with [(pcolor = green - 3.5) and pxcor = positionx + i and pycor = positiony]
        [ enflammer]
      ]
  ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
12
224
621
834
-1
-1
1.0
1
10
1
1
1
0
0
0
1
-300
300
-300
300
1
1
1
ticks
30.0

BUTTON
1012
158
1081
191
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1103
157
1166
190
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
216
51
388
84
densité
densité
0
100
75.0
1
1
%
HORIZONTAL

SLIDER
23
99
195
132
largeur-rivières
largeur-rivières
0
10
0.0
1
1
m
HORIZONTAL

SLIDER
22
156
194
189
intensité-vent
intensité-vent
0
50
50.0
1
1
km/h
HORIZONTAL

SLIDER
23
50
195
83
humidité
humidité
0
100
0.0
1
1
%
HORIZONTAL

SLIDER
509
148
690
181
hauteur-parcelles
hauteur-parcelles
20
150
100.0
1
1
m
HORIZONTAL

SLIDER
509
102
688
135
largeur-parcelles
largeur-parcelles
20
150
100.0
1
1
m
HORIZONTAL

SLIDER
697
102
875
135
largeur-coupe-feu
largeur-coupe-feu
0
40
2.0
1
1
m
HORIZONTAL

MONITOR
1246
73
1360
118
Pourcentage brulé
(arbres-brules / arbres-initiaux)\n* 100
1
1
11

TEXTBOX
24
11
174
36
Environnement 
20
0.0
1

TEXTBOX
511
10
661
35
Parcelles\n
20
0.0
1

TEXTBOX
998
10
1148
35
Simulation
20
0.0
1

SLIDER
216
102
388
135
foyer-de-feu
foyer-de-feu
0
20
1.0
1
1
NIL
HORIZONTAL

MONITOR
1374
74
1494
119
Pourcentage sauvé
100 - (arbres-brules / arbres-initiaux)\n* 100
1
1
11

PLOT
1246
134
1652
324
Taux d'accupation du terrain par les arbres
NIL
%
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (count patches with [pcolor = green - 3.5] / count patches) * 100"

SWITCH
509
50
653
83
coupes-feux
coupes-feux
1
1
-1000

PLOT
1246
330
1797
480
Pertes (en euros) induite par les coupes-feux
NIL
euros
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "set-plot-y-range 0 prix-arbre * count patches" "if coupes-feux [plot count patches with [pcolor = brown] * densité / 100 * prix-arbre]"

PLOT
1246
488
1707
638
Pertes (en euros) induite par le feu
NIL
NIL
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "set-plot-y-range 0 prix-arbre * count patches" "plot count patches with [pcolor = gray] * prix-arbre"

SLIDER
1002
99
1174
132
prix-arbre
prix-arbre
1
100
100.0
1
1
euros
HORIZONTAL

PLOT
1248
645
1988
795
Valeur totale de la parcelle (en euros)
NIL
euros
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "set-plot-y-range 0 prix-arbre * count patches" "plot count patches with [pcolor = green - 3.5] * prix-arbre"

CHOOSER
230
149
368
194
sens-vent
sens-vent
"Nord-Sud" "Sud-Nord" "Est-Ouest" "Ouest-Est"
2

SLIDER
1001
51
1173
84
taille-arbre
taille-arbre
0
30
30.0
1
1
mètres
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
