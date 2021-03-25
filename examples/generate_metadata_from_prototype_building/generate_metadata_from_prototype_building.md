# Generate Metadata From Prototype Building Example
This is an example script which will output building metadata files based on DOE prototype buildings.
## Executing
```bundle exec ruby generate_metadata_from_prototype_building.rb -b BUILDING -f FORMAT -n ONTOLOGY```
## Arguments
`-b, --building`: Name of DOE prototype building to generate a metadata model from

`-f, --format`: The output format of the metadata file

`-n, --ontology`: The target ontology for the generated metadata file

### Supported Building Arguments
- SecondarySchool
- PrimarySchool
- SmallOffice
- MediumOffice
- LargeOffice
- SmallHotel
- LargeHotel
- Warehouse
- RetailStandalone
- RetailStripmall
- QuickServiceRestaurant
- FullServiceRestaurant
- MidriseApartment
- HighriseApartment
- Hospital
- Outpatient
- Laboratory
- LargeDataCenterHighITE
- LargeDataCenterLowITE
- SmallDataCenterHighITE
- SmallDataCenterLowITE

### Supported Format/Ontology Matrix
| Ontology/Format | Haystack | Brick |
| --------------- | -------- | ----- |
| json            | yes      | no    |
| ttl             | no       | yes   |
| nq              | no       | yes   |
