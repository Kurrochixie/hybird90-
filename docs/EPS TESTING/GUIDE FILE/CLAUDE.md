- AABBCC
│  │  │
│  │  └─ Byte rendah: Status Alarm + Bell (CC)
│  └─ Byte tinggi: Status Trouble (BB)  
└─ Address Slave (AA)
- button press kirim data ke tx esp32 yang file esp32 ada di "C:\Users\melin\Downloads\tes\src\main.cpp" \
button sending message :
system reset = "r"\
drill = "d"\
silenced = "s"\
acknowladge = "a"
- {"timestamp":5080561,"data":"51DD <STX>01 <STX>022000 <STX>033F00 <STX>043F00 <STX>053F00 <STX>063F00 <STX>073F00 <STX>083F00 <STX>091F00 <STX>102000 <STX>112000 <STX>122000 <STX>132000 <STX>14 <STX>15 <STX>16 <STX>17 <STX>18 <STX>192000 <STX>202000 <STX>212000 <STX>22 <STX>232000 <STX>242000 <STX>253F00 <STX>263F00 <STX>273F00 <STX>283F00 <STX>293F00 <STX>303F00 <STX>31 <STX>323F00 <STX>332000 <STX>34 <STX>352000 <STX>362000 <STX>37 <STX>382000 <STX>39 <STX>40 <STX>41 <STX>42 <STX>43 <STX>44 <STX>45 <STX>46 <STX>47 <STX>48 <STX>49 <STX>50 <STX>51 <STX>52 <STX>53 <STX>54 <STX>55 <STX>56 <STX>57 <STX>58 <STX>592000 <STX>603F00 <STX>612000 <STX>622000 <STX>632000 <STX><ETX>|FB:SKIP|TS:5080561|MODE:Offline","clients":5,"freeHeap":225576} \
ini adalah bentuk data yang diterima dari websocket
- BITMAP UNTUK STATUS LED \
 Bit 6: AC Power     (0x40) → 0=ON, 1=OFF
  Bit 5: DC Power     (0x20) → 0=ON, 1=OFF
  Bit 4: Alarm        (0x10) → 0=ON, 1=OFF
  Bit 3: Trouble      (0x08) → 0=ON, 1=OFF
  Bit 2: Drill        (0x04) → 0=ON, 1=OFF
  Bit 1: Silenced     (0x02) → 0=ON, 1=OFF
  Bit 0: Disabled     (0x01) → 0=ON, 1=OFF\
\
Bit 7 tidak digunakan.
- jangan lakukan apapun terhadap metode parsing yang sudah ada