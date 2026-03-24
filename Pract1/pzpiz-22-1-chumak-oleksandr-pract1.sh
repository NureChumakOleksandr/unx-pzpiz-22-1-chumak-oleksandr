width=9
for i in {1..5}; do
  row=""
  for ((k=0; k<=width; k+=1)); do
    if (( k <= (width/2 - i) || k >= (width/2 + i) )); then
      row+=" "
    else 
      row+="#"
    fi
  done
  echo "$row"
done

for i in {2..5}; do
  row=""
  for ((k=0; k<=width; k+=1)); do
    if (( k <= (width/2 - i) || k >= (width/2 + i) )); then
      row+=" "
    else 
      row+="#"
    fi
  done
  echo "$row"
done

currentRow=2;
until(( currentRow > 5)); do
    row=""
    for ((k=0; k<=width; k+=1)); do
      if (( k <= (width/2 - currentRow) || k >= (width/2 + currentRow) )); then
        row+=" "
      else 
        row+="#"
      fi
    done
    echo "$row"
    (( currentRow++ ))
done

treeTrunkHeight=2
while(( treeTrunkHeight > 0)); do
  echo "   ###   "
  ((treeTrunkHeight--))
done

echo "#########";
