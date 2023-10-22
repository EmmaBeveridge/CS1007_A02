BEGIN {FS = OFS = ",";} #BEGIN: Executes once before file processed. Sets input and output field separators to comma for csv processing
{fuelUseForVehicle[$(NF-1)]+=$NF;} #Executes for each record in csv file. Adds fuel use for given journey of current route to fuel sum for vehicle with id in record. Running total of fuel stored in associative array with vehicle ID ued as key and fuel sum is value. Vehicle ID indexed as 2nd to last field and fuel use as last field in record
END { #END: Executes once after all records processed. 
    for (vehicle in fuelUseForVehicle){
        printf "%s,%d\n", vehicle, fuelUseForVehicle[vehicle]; #Iterates over fuel totals array and prints a string in csv record format with vehicle ID field and fuel total for route field
    }
}
