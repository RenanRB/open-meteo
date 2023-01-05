import Foundation
import Vapor
import SwiftPFor2D
import SwiftNetCDF


/**
 https://esgf-data.dkrz.de/search/cmip6-dkrz/
 https://esgf-node.llnl.gov/search/cmip6/
 
 INTERESSTING:
 
 CMCC-CM2-VHR4 (CMCC Italy) https://www.wdc-climate.de/ui/cmip6?input=CMIP6.HighResMIP.CMCC.CMCC-CM2-VHR4
 0.3125°
 6h: 2m temp, humidity, wind, surface temp,
 daily: 2m temp, humidity. wind, precip, longwave,
 monthly: temp, clouds, precip, runoff, wind, soil moist 1 level, humidity, snow,
 NO daily min/max directly
 
 FGOALS-f3  (CAS China) https://www.wdc-climate.de/ui/cmip6?input=CMIP6.HighResMIP.CAS.FGOALS-f3-H.highresSST-future
 0.25°
 3h: air tmp, clc, wind, hum, sw
 6h: missing temperature for higher altitude,
 day: missing temperature for land,clc, wind, hum, precip, sw,
 monthly: temp, clc, wind, hum, precip,
 NO daily min/max directly
 
 HiRAM-SIT-HR (RCEC taiwan) https://www.wdc-climate.de/ui/cmip6?input=CMIP6.HighResMIP.AS-RCEC.HiRAM-SIT-HR
 0.23°
 daily: 2m temp, surface temp (min max), clc, precip, wind, snow, swrad
 monthly: 2m temp, clc, wind, hum, snow, swrad,
 
 MRI-AGCM3-2-S (MRI Japan, ) https://www.wdc-climate.de/ui/cmip6?input=CMIP6.HighResMIP.MRI.MRI-AGCM3-2-S.highresSST-present
 0.1875°
 3h: 2m temp, wind, soil moisture, hum, surface temperature
 day: temp, clc, soild moist, wind, hum, runoff, precip, snow, swrad,
 month: same
 
 MEDIUM:
 
 NICAM16-9S https://gmd.copernicus.org/articles/14/795/2021/
 0.14°, but only 2040-2050 and 1950–1960, 2000–2010 (high computational cost hindered us from running NICAM16-9S for 100 years)
 1h: precip
 3h: precip, clc, snow, swrad (+cs), temp, wind, pres, hum
 day: temp, clc, wind, precip, snow, hum, swrad,
 month: temp, (clc), precio, runoff,
 
 LESS:
 
 CESM1-CAM5-SE-HR -> old model from 2012
 native ne120 spectral element grid... 25km
 day: only ocean
 monthly: NO 2m temp, surface (min,max), clc, wind, hum, snow, swrad,
 
 HiRAM-SIT-LR: only present
 
 ACCESS-OM2-025 -> only ocean
 AWI-CM-1-1-HR: onlt oean
 
 ECMWF-IFS-HR:
 0.5°
 6h: 2m temp, wind, hum, pres
 day: 2m temp, clouds, precip, wind, hum, snow, swrad, surface temp (min/max),
 month: temp 2m, clc, wind, leaf area index, precip, runoff, soil moist, soil temp, hum,
 
 IPSL-CM6A-ATM-ICO-VHR: ipsl france: only 1950-2014
 
 MRI-AGCM3-2-H
 0.5°
 6h: pres, 2m temp, wind, hum
 day: 2m temp, clc, wind, soil moist, precip, runoff, snow, hum, swrad, (T pressure levels = only 1000hpa.. massive holes!)
 mon: 2m temp, surface temp, clc, wind, hum, swrad,
 
 
 Sizes:
 MRI: Raw 2.15TB, Compressed 413 GB
 HiRAM_SIT_HR_daily: Raw 1.3TB, Compressed 210 GB
 FGLOALS: Raw 1.2 TB, Compressed 120 GB
 */

enum Cmip6Domain: String, GenericDomain {
    case CMCC_CM2_VHR4_daily
    case FGOALS_f3_H_daily
    case HiRAM_SIT_HR_daily
    case MRI_AGCM3_2_S_daily
    
    var soureName: String {
        switch self {
        case .CMCC_CM2_VHR4_daily:
            return "CMCC-CM2-VHR4"
        case .FGOALS_f3_H_daily:
            return "FGOALS-f3-H"
        case .HiRAM_SIT_HR_daily:
            return "HiRAM-SIT-HR"
        case .MRI_AGCM3_2_S_daily:
            return "MRI-AGCM3-2-S"
        }
    }
    
    var gridName: String {
        switch self {
        case .CMCC_CM2_VHR4_daily:
            return "gr"
        case .FGOALS_f3_H_daily:
            return "gr"
        case .HiRAM_SIT_HR_daily:
            return "gn"
        case .MRI_AGCM3_2_S_daily:
            return "gn"
        }
    }
    
    var institute: String {
        switch self {
        case .CMCC_CM2_VHR4_daily:
            return "CMC"
        case .FGOALS_f3_H_daily:
            return "CAS"
        case .HiRAM_SIT_HR_daily:
            return "AS-RCEC"
        case .MRI_AGCM3_2_S_daily:
            return "MRI"
        }
    }
    
    var omfileDirectory: String {
        return "\(OpenMeteo.dataDictionary)omfile-\(rawValue)/"
    }
    var downloadDirectory: String {
        return "\(OpenMeteo.dataDictionary)download-\(rawValue)/"
    }
    var omfileArchive: String? {
        return "\(OpenMeteo.dataDictionary)archive-\(rawValue)/"
    }
    /// Filename of the surface elevation file
    var surfaceElevationFileOm: String {
        "\(omfileDirectory)HSURF.om"
    }
    
    var dtSeconds: Int {
        return 24*3600
    }
    
    private static var elevationCMCC_CM2_VHR4 = try? OmFileReader(file: Self.CMCC_CM2_VHR4_daily.surfaceElevationFileOm)
    private static var elevationFGOALS_f3_H = try? OmFileReader(file: Self.FGOALS_f3_H_daily.surfaceElevationFileOm)
    private static var elevationHiRAM_SIT_HR = try? OmFileReader(file: Self.HiRAM_SIT_HR_daily.surfaceElevationFileOm)
    private static var elevationMRI_AGCM3_2_S = try? OmFileReader(file: Self.MRI_AGCM3_2_S_daily.surfaceElevationFileOm)
    
    var elevationFile: OmFileReader<MmapFile>? {
        switch self {
        case .CMCC_CM2_VHR4_daily:
            return Self.elevationCMCC_CM2_VHR4
        case .FGOALS_f3_H_daily:
            return Self.elevationFGOALS_f3_H
        case .HiRAM_SIT_HR_daily:
            return Self.elevationHiRAM_SIT_HR
        case .MRI_AGCM3_2_S_daily:
            return Self.elevationMRI_AGCM3_2_S
        }
    }
    
    var omFileLength: Int {
        // has no realtime updates
        return 0
    }
    
    var grid: Gridable {
        switch self {
        case .CMCC_CM2_VHR4_daily:
            return RegularGrid(nx: 1152, ny: 768, latMin: -90, lonMin: -180, dx: 0.3125, dy: 180/768)
        case .FGOALS_f3_H_daily:
            return RegularGrid(nx: 1440, ny: 720, latMin: -90, lonMin: -180, dx: 0.25, dy: 0.25)
        case .HiRAM_SIT_HR_daily:
            return RegularGrid(nx: 1536, ny: 768, latMin: -90, lonMin: -180, dx: 360/1536, dy: 180/768)
        case .MRI_AGCM3_2_S_daily:
            return RegularGrid(nx: 1920, ny: 960, latMin: -90, lonMin: -180, dx: 0.1875, dy: 0.1875)
        }
    }
    
    var versionOrography: (altitude: String, landmask: String)? {
        switch self {
        case .CMCC_CM2_VHR4_daily:
            return ("20210330", "20210330")
        case .FGOALS_f3_H_daily:
            return ("20201204", "20210121")
        case .HiRAM_SIT_HR_daily:
            return nil
        case .MRI_AGCM3_2_S_daily:
            return ("20200305", "20200305")
        }
    }
}

enum Cmip6Variable: String, CaseIterable {
    case pressure_msl
    case temperature_2m_min
    case temperature_2m_max
    case temperature_2m
    case cloudcover
    case precipitation
    case runoff
    case snowfall_water_equivalent
    case relative_humidity_2m_min
    case relative_humidity_2m_max
    case relative_humidity_2m
    case windspeed_10m
    
    case surface_temperature
    
    /// Moisture in Upper Portion of Soil Column.
    case soil_moisture_0_to_10cm
    case shortwave_radiation
    
    enum TimeType {
        case monthly
        case yearly
        case tenYearly
    }
    
    func version(for domain: Cmip6Domain) -> String {
        switch domain {
        case .CMCC_CM2_VHR4_daily:
            if self == .precipitation {
                return "20210308"
            }
            return "20190725"
        case .FGOALS_f3_H_daily:
            return "20190817"
        case .HiRAM_SIT_HR_daily:
            return "20210713" // "20210707"
        case .MRI_AGCM3_2_S_daily:
            return "20190711"
        }
    }
    
    var scalefactor: Float {
        switch self {
        case .pressure_msl:
            return 10
        case .temperature_2m_min:
            return 20
        case .temperature_2m_max:
            return 20
        case .temperature_2m:
            return 20
        case .cloudcover:
            return 1
        case .precipitation:
            return 10
        case .runoff:
            return 10
        case .snowfall_water_equivalent:
            return 10
        case .relative_humidity_2m_min:
            return 1
        case .relative_humidity_2m_max:
            return 1
        case .relative_humidity_2m:
            return 1
        case .windspeed_10m:
            return 10
        case .surface_temperature:
            return 20
        case .soil_moisture_0_to_10cm:
            return 1000
        case .shortwave_radiation:
            return 1
        }
    }
    
    func domainTimeRange(for domain: Cmip6Domain) -> TimeType? {
        switch domain {
        case .MRI_AGCM3_2_S_daily:
            switch self {
            case .pressure_msl:
                return .yearly
            case .temperature_2m_min:
                return .yearly
            case .temperature_2m_max:
                return .yearly
            case .temperature_2m:
                return .yearly
            case .cloudcover:
                return .yearly
            case .precipitation:
                return .yearly
            case .runoff:
                return .yearly
            case .snowfall_water_equivalent:
                return .yearly
            case .relative_humidity_2m_min:
                return .yearly
            case .relative_humidity_2m_max:
                return .yearly
            case .relative_humidity_2m:
                return .yearly
            case .surface_temperature:
                return .yearly
            case .soil_moisture_0_to_10cm:
                return .yearly
            case .shortwave_radiation:
                return .yearly
            case .windspeed_10m:
                return .yearly
            }
        case .CMCC_CM2_VHR4_daily:
            switch self {
            case .relative_humidity_2m:
                return .monthly
            case .precipitation:
                // only precip is in yearly files...
                return .yearly
            case .temperature_2m:
                return .monthly
            case .windspeed_10m:
                return .monthly
            default:
                return nil
            }
        case .FGOALS_f3_H_daily:
            // no near surface RH, only specific humidity
            switch self {
            case .relative_humidity_2m:
                return .yearly
            case .cloudcover:
                return .yearly
            case .temperature_2m:
                return .yearly
            case .pressure_msl:
                return .yearly
            case .snowfall_water_equivalent:
                return .yearly
            case .shortwave_radiation:
                return .yearly
            case .windspeed_10m:
                return .yearly
            case .precipitation:
                return .yearly
            default:
                return nil
            }
        case .HiRAM_SIT_HR_daily:
            // no u/v wind components near surface
            switch self {
            case .temperature_2m:
                return .yearly
            case .temperature_2m_max:
                return .yearly
            case .temperature_2m_min:
                return .yearly
            case .cloudcover:
                return .yearly
            case .precipitation:
                return .yearly
            case .snowfall_water_equivalent:
                return .yearly
            case .relative_humidity_2m:
                return .yearly
            case .shortwave_radiation:
                return .yearly
            case .windspeed_10m:
                return .yearly
            default:
                return nil
            }
        }
    }
    
    /// hourly the same but no min/max. Hourly one file per month. Daily = yearly file
    var shortname: String {
        switch self {
        case .pressure_msl:
            return "psl"
        case .temperature_2m_min:
            return "tasmin"
        case .temperature_2m_max:
            return "tasmax"
        case .temperature_2m:
            return "tas"
        case .cloudcover:
            return "clt"
        case .precipitation:
            return "pr"
        case .relative_humidity_2m_min:
            return "hursmax"
        case .relative_humidity_2m_max:
            return "hursmin"
        case .relative_humidity_2m:
            return "hurs"
        case .runoff:
            return "mrro"
        case .snowfall_water_equivalent:
            return "prsn" //kg m-2 s-1
        case .soil_moisture_0_to_10cm: // Moisture in Upper Portion of Soil Column
            return "mrsos"
        case .shortwave_radiation:
            return "rsds"
        case .surface_temperature:
            return "tslsi"
        case .windspeed_10m:
            return "sfcWind"
        }
    }
    
    var multiplyAdd: (multiply: Float, add: Float)? {
        switch self {
        case .temperature_2m_min:
            fallthrough
        case .temperature_2m_max:
            fallthrough
        case .temperature_2m:
            return (1, -273.15)
        case .pressure_msl:
            return (1/100, 0)
        case .precipitation:
            fallthrough
        case .snowfall_water_equivalent:
            fallthrough
        case .runoff:
            return (3600*24, 0)
        default:
            return nil
        }
    }
}

struct DownloadCmipCommand: AsyncCommandFix {
    /// 6k locations require around 200 MB memory for a yearly time-series
    static var nLocationsPerChunk = 6_000
    
    struct Signature: CommandSignature {
        @Argument(name: "domain")
        var domain: String
    }
    
    var help: String {
        "Download CMIP6 data and convert"
    }
    
    func run(using context: CommandContext, signature: Signature) async throws {
        let logger = context.application.logger
        
        guard let domain = Cmip6Domain.init(rawValue: signature.domain) else {
            fatalError("Invalid domain '\(signature.domain)'")
        }
        
        // Automatically try all servers. From fastest to slowest
        let servers = ["https://esgf3.dkrz.de/thredds/fileServer/cmip6/",
                       "https://esgf.ceda.ac.uk/thredds/fileServer/esg_cmip6/",
                       "https://esgf-data1.llnl.gov/thredds/fileServer/css03_data/CMIP6/",
                       "https://esgf-data04.diasjp.net/thredds/fileServer/esg_dataroot/CMIP6/",
                       "https://esg.lasg.ac.cn/thredds/fileServer/esg_dataroot/CMIP6/"]
        
        guard let yearlyPath = domain.omfileArchive else {
            fatalError("yearly archive path not defined")
        }
        try FileManager.default.createDirectory(atPath: domain.downloadDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: yearlyPath, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: domain.omfileDirectory, withIntermediateDirectories: true)
        
        let curl = Curl(logger: logger, client: context.application.dedicatedHttpClient, readTimeout: 3600*3, retryError4xx: false)
        let source = domain.soureName
        let grid = domain.gridName
        
        /// Make sure elevation information is present. Otherwise download it
        if let version = domain.versionOrography, !FileManager.default.fileExists(atPath: domain.surfaceElevationFileOm) {
            let ncFileAltitude = "\(domain.downloadDirectory)orog_fx.nc"
            if !FileManager.default.fileExists(atPath: ncFileAltitude) {
                let uri = "HighResMIP/\(domain.institute)/\(source)/highresSST-present/r1i1p1f1/fx/orog/\(grid)/v\(version.altitude)/orog_fx_\(source)_highresSST-present_r1i1p1f1_\(grid).nc"
                try await curl.download(servers: servers, uri: uri, toFile: ncFileAltitude)
            }
            let ncFileLandFraction = "\(domain.downloadDirectory)sftlf_fx.nc"
            if !FileManager.default.fileExists(atPath: ncFileLandFraction) {
                let uri = "HighResMIP/\(domain.institute)/\(source)/highresSST-present/r1i1p1f1/fx/sftlf/\(grid)/v\(version.landmask)/sftlf_fx_\(source)_highresSST-present_r1i1p1f1_\(grid).nc"
                try await curl.download(servers: servers, uri: uri, toFile: ncFileLandFraction)
            }
            var altitude = try NetCDF.read(path: ncFileAltitude, short: "orog", fma: nil)
            let landFraction = try NetCDF.read(path: ncFileLandFraction, short: "sftlf", fma: nil)
            
            for i in altitude.data.indices {
                if landFraction.data[i] < 0.5 {
                    altitude.data[i] = -999
                }
            }
            //try altitude.transpose().writeNetcdf(filename: "\(domain.downloadDirectory)elevation.nc", nx: domain.grid.nx, ny: domain.grid.ny)
            try OmFileWriter(dim0: domain.grid.ny, dim1: domain.grid.nx, chunk0: 20, chunk1: 20).write(file: domain.surfaceElevationFileOm, compressionType: .p4nzdec256, scalefactor: 1, all: altitude.data)
            
            // TODO: delete temporary nc files
        }
        
        for variable in Cmip6Variable.allCases {
            guard let timeType = variable.domainTimeRange(for: domain) else {
                continue
            }
            
            for year in 1950...1950 { // 2014
                logger.info("Downloading \(variable) for year \(year)")
                let version = variable.version(for: domain)
                
                switch timeType {
                case .monthly:
                    let omFile = "\(yearlyPath)\(variable.rawValue)_\(year).nc"
                    if FileManager.default.fileExists(atPath: omFile) {
                        continue
                    }
                    
                    // download month files and combine to yearly file
                    let short = variable.shortname
                    for month in 1...12 {
                        let ncFile = "\(domain.downloadDirectory)\(short)_\(year)\(month).nc"
                        let monthlyOmFile = "\(domain.downloadDirectory)\(short)_\(year)\(month).om"
                        if !FileManager.default.fileExists(atPath: ncFile) {
                            let endOfMonth = Timestamp(year, month, 1).add(hours: -1).format_YYYYMMdd
                            let uri = "HighResMIP/\(domain.institute)/\(source)/highresSST-present/r1i1p1f1/day/\(short)/\(grid)/v\(version)/\(short)_day_\(source)_highresSST-present_r1i1p1f1_\(grid)_\(year)\(month)01-\(endOfMonth).nc"
                            try await curl.download(servers: servers, uri: uri, toFile: ncFile)
                            let array = try NetCDF.read(path: ncFile, short: short, fma: variable.multiplyAdd)
                            try OmFileWriter(dim0: array.nLocations, dim1: array.nTime, chunk0: domain.grid.nx, chunk1: array.nTime).write(file: monthlyOmFile, compressionType: .p4nzdec256, scalefactor: variable.scalefactor, all: array.data)
                        }
                    }
                    
                    
                    
                    // TODO: delete temporary nc files
                case .yearly:
                    let omFile = "\(yearlyPath)\(variable.rawValue)_\(year).nc"
                    if FileManager.default.fileExists(atPath: omFile) {
                        continue
                    }
                    /// `FGOALS_f3_H` has no near surface relative humidity, calculate from specific humidity
                    let calculateRhFromSpecificHumidity = domain == .FGOALS_f3_H_daily && variable == .relative_humidity_2m
                    let short = calculateRhFromSpecificHumidity ? "huss" : variable.shortname
                    let ncFile = "\(domain.downloadDirectory)\(short)_\(year).nc"
                    if !FileManager.default.fileExists(atPath: ncFile) {
                        let uri = "HighResMIP/\(domain.institute)/\(source)/highresSST-present/r1i1p1f1/day/\(short)/\(grid)/v\(version)/\(short)_day_\(source)_highresSST-present_r1i1p1f1_\(grid)_\(year)0101-\(year)1231.nc"
                        try await curl.download(servers: servers, uri: uri, toFile: ncFile)
                    }
                    var array = try NetCDF.read(path: ncFile, short: short, fma: variable.multiplyAdd)
                    if calculateRhFromSpecificHumidity {
                        let pressure = try NetCDF.read(path: "\(domain.downloadDirectory)psl_\(year).nc", short: "psl", fma: (1/100, 0))
                        let elevation = try domain.elevationFile!.readAll()
                        let temp = try NetCDF.read(path: "\(domain.downloadDirectory)tas_\(year).nc", short: "tas", fma: (1, -273.15))
                        array.data.multiplyAdd(multiply: 1000, add: 0)
                        array.data = Meteorology.specificToRelativeHumidity(specificHumidity: array, temperature: temp, sealLevelPressure: pressure, elevation: elevation)
                        //try array.transpose().writeNetcdf(filename: "\(domain.downloadDirectory)rh.nc", nx: domain.grid.nx, ny: domain.grid.ny)
                    }
                    try OmFileWriter(dim0: array.nLocations, dim1: array.nTime, chunk0: 6, chunk1: 183).write(file: omFile, compressionType: .p4nzdec256, scalefactor: variable.scalefactor, all: array.data)
                    
                    // TODO: delete temporary nc files
                case .tenYearly:
                    fatalError("ten yearly")
                }
                

            }
            
        }
    }
}

extension NetCDF {
    fileprivate static func read(path: String, short: String, fma: (multiply: Float, add: Float)?) throws -> Array2DFastTime {
        guard let ncFile = try NetCDF.open(path: path, allowUpdate: false) else {
            fatalError("Could not open nc file for \(short)")
        }
        guard let ncVar = ncFile.getVariable(name: short) else {
            fatalError("Could not open nc variable for \(short)")
        }
        guard let ncFloat = ncVar.asType(Float.self) else {
            fatalError("Not a float nc variable")
        }
        /// 3d spatial oriented file
        let dim = ncVar.dimensionsFlat
        let nt = dim.count == 3 ? dim[0] : 1
        let nx = dim[dim.count-1]
        let ny = dim[dim.count-2]
        /// transpose to fast time
        var spatial = Array2DFastSpace(data: try ncFloat.read(), nLocations: nx*ny, nTime: nt)
        spatial.data.shift180Longitude(nt: nt, ny: ny, nx: nx)
        if let fma {
            spatial.data.multiplyAdd(multiply: fma.multiply, add: fma.add)
        }
        //try spatial.writeNetcdf(filename: "\(path)4", nx: dim[2], ny: dim[1])
        return spatial.transpose()
    }
}

extension Curl {
    /// Retry download from multiple servers
    /// NOTE: retry 404 should be disabled!
    fileprivate func download(servers: [String], uri: String, toFile: String) async throws {
        for (i,server) in servers.enumerated() {
            do {
                let url = "\(server)\(uri)"
                try await download(url: url, toFile: toFile, bzip2Decode: false)
                break
            } catch CurlError.downloadFailed(let code) {
                if code == .notFound && i != servers.count-1 {
                    continue
                }
                throw CurlError.downloadFailed(code: code)
            }
        }
    }
}