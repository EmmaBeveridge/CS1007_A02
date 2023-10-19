BEGIN {FS = OFS = ",";}
{fuelUseForVehicle[$(NF-1)]+=$NF;}
END {
    for (vehicle in fuelUseForVehicle){
        printf "%s,%d\n", vehicle, fuelUseForVehicle[vehicle];
    }
}
