# mini_nf

```
# Test run
nextflow run main.nf -stub-run
```

### Option 0.1: Pull data from a url

```
nextflow run main.nf \
  --input_url "https://github.com/nextstrain/zika-tutorial/archive/refs/heads/master.zip"
```

Output:

```
N E X T F L O W  ~  version 21.10.6
Launching `main.nf` [zen_swanson] - revision: 89120e33aa
executor >  local (1)
[e5/a0ed73] process > wget_url (1)         [100%] 1 of 1, cached: 1 ✔
[95/98cace] process > nextstrain_build (1) [100%] 1 of 1 ✔
Completed at: 06-Jan-2022 16:29:02
Duration    : 1m 35s
CPU hours   : (a few seconds)
Succeeded   : 1
Cached      : 1
```

### Option 1: Wrap everything in one process

```
nextflow run main.nf \
  --input_dir "path/to/zika-tutorial"
```

Output:

```
N E X T F L O W  ~  version 21.04.3
Launching `main.nf` [soggy_liskov] - revision: 28e8bf36de
executor >  local (1)
[ce/52d024] process > nextstrain_build (1) [100%] 1 of 1 ✔

Completed at: 29-Dec-2021 13:05:12
Duration    : 2m 42s
CPU hours   : (a few seconds)
Succeeded   : 1

ls -1 results

#> results/
#>   |_ zika-tutorial/
#>       |_ auspice/zika.json   #<= this one!
#>       |_ results/            # other intermediate files
```

### Option 2: Wrap each module in a process

```
nextflow run main.nf \
  --sequences "data/sequences.fasta" \
  --metadata "data/metadata.tsv" \
  --exclude "data/dropped_strains.txt" \
  --reference "data/zika_outgroup.gb" \
  --colors "data/colors.tsv" \
  --lat_longs "data/lat_longs.tsv" \
  --auspice_config "data/auspice_config.json"
```

Output:

```
N E X T F L O W  ~  version 21.04.3
Launching `main.nf` [scruffy_elion] - revision: ae2b2117f5
executor >  local (9)
[55/4d3a4a] process > index (1)     [100%] 1 of 1 ✔
[67/43577b] process > filter (1)    [100%] 1 of 1 ✔
[87/554798] process > align (1)     [100%] 1 of 1 ✔
[20/cf2861] process > tree (1)      [100%] 1 of 1 ✔
[58/dd4a84] process > refine (1)    [100%] 1 of 1 ✔
[24/e74540] process > ancestral (1) [100%] 1 of 1 ✔
[44/0b2945] process > translate (1) [100%] 1 of 1 ✔
[b7/ef345b] process > traits (1)    [100%] 1 of 1 ✔
[a4/a8271c] process > export (1)    [100%] 1 of 1 ✔
WARN: Task runtime metrics are not reported when using macOS without a container engine
Completed at: 29-Dec-2021 13:25:19
Duration    : 1m 46s
CPU hours   : (a few seconds)
Succeeded   : 9

ls -1 results

#> results/
#>   |_ sequences_filtered.fasta
#>   |_ sequences.fasta
#>   |_ sequences_index.tsv
#>   |_ sequences_filtered_aligned.fasta
#>   |_ sequences_filtered_aligned_raw.nwk
#>   |_ sequences_filtered_aligned_branch_lengths.json
#>   |_ sequences_filtered_aligned.nwk
#>   |_ sequences_filtered_aligned_traits.json
#>   |_ sequences_filtered_aligned_nt_muts.json
#>   |_ sequences_filtered_aligned_aa_muts.json
#>   |_ auspice/                                 #<= this one!
#>   |_ report.html
#>   |_ timeline.html
```

## Notes

Build a dockerimage

```
# Start docker desktop
docker build . -t ncov_doc # Assume Dockerfile in current directory

# Interactive session
docker run -it ncov_doc
```

## Debug notes

Nextflow creates a `work` directory where it stores cached intermediate files and scripts. Each hashed directory matches the hash in the print out field (e.g. `fa/60fdb1`) so you can check inputfile scope for each process. Less likely to have filename collisions.

```
$ nextflow run main.nf --input_dir zika-tutorial
N E X T F L O W  ~  version 21.10.6
Launching `main.nf` [scruffy_cajal] - revision: ae2b2117f5
executor >  local (1)
[fa/60fdb1] process > nextstrain_build (1) [100%] 1 of 1 ✔
WARN: Task runtime metrics are not reported when using macOS without a container engine

$ find work/
work/
  |_ conda/          # <= if you use -profile conda, stores env
  |_ singularity/    # <= if you use -profile singularity, stores imgs
  |
  |_ fa/
    |_ f60fdb1c0a50c25844caab3be389369/
      |_ zika-tutorial/       #<= input
      |  |_ auspice/          #<= output
      |  |_ results/
      |
      |_ .command.sh
      |_ .command.begin
      |_ .command.run
      |_ .exitcode
      |_ .command.log
      |_ .command.trace
      |
      |_ .command.err        #<= check these files to debug
      |_ .command.out
```
