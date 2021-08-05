module BolsigHelpers

using DataFrames, CSV, Interpolations

export load_from_bolsig


headers = Dict(
    :mean_energy => "Mean energy (eV)",
    :mobility => "Mobility *N (1/m/V/s)",
    :diffusion_coef => "Diffusion coefficient *N (1/m/s)",
    :energy_mobility => "Energy mobility *N (1/m/V/s)",
    :energy_diffusion_coef => "Energy diffusion coef. D*N (1/m/s)",
    :total_coll_freq => "Total collision freq. /N (m3/s)",
    :momentum_coll_freq => "Momentum frequency /N (m3/s)",
    :total_ion_freq  => "Total ionization freq. /N (m3/s)",
    :townsend_alpha => "Townsend ioniz. coef. alpha/N (m2)"
)



"""
	findtable(tablename, filename)

Returns tupel with start and end line numbers of a table which contains
`tablename` in its header and exists in the Bolsig+ output file `filename`. 
"""
function findtable(tablename, filename)
	startpos = 0
	endpos = 0

	open(filename) do file 
		for (linenumber, line) in enumerate(eachline(file))
			if occursin(tablename, line)
				startpos = linenumber
			end
			if startpos != 0
				if isempty(strip(line))
					endpos = linenumber
					return (startpos, endpos)
				end
			end
		end
	end

	(startpos, endpos)
end

"""
	loadtable(tablename, filename)

Returns the table in the Bolsig+ output file `filename` which contains
`tablename` in its header. 
"""
function loadtable(tablename, filename)
	(startpos, endpos) = findtable(tablename, filename)
	# load DataFrame from CSV file, skip the header in the file (datarow=startpos+1) 
	# and assign column names manually (header=["E", tablename])
	df = DataFrame(CSV.File(filename,header=["E", tablename], datarow=startpos+1, limit=endpos-startpos-1, delim="\t"))

end

"""
	interpolatetable(tablename, filename)

Returns callable interpolation of table `tablename` from Bolsig+ output data file `filename`.
"""
function interpolatetable(tablename, filename)
	df = loadtable(tablename, filename)

	LinearInterpolation(df[!,:E], df[!,tablename], extrapolation_bc=Line())
end


"""
    load_from_bolsig(file, name)
Loads the table `name` from a Bolsig+ output file and returns an interpolation object.
Possible table names are: 
    * `:mean_energy`: Mean electron energy in eV
    * `:mobility`: Mobility *N (1/m/V/s)
    * `:diffusion_coef`: Diffusion coefficient *N (1/m/s)
    * `:energy_mobility`: Energy mobility *N (1/m/V/s)
    * `:energy_diffusion_coef`: Energy diffusion coef. D*N (1/m/s)
    * `:total_coll_freq`: Total collision freq. /N (m3/s)
    * `:momentum_coll_freq`: Momentum frequency /N (m3/s)
    * `:total_ion_freq`: Total ionization freq. /N (m3/s)
    * `:townsend_alpha`: Townsend ioniz. coef. alpha/N (m2)
"""
function load_from_bolsig(file, name)
    return interpolatetable(headers[name], file)
end


end # module
