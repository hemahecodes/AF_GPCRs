#!/bin/bash

$PDB_LIST= $1
$STATE = $2

source /shared/home/hmartin/miniconda3/etc/profile.d/conda.sh
conda activate /shared/home/hmartin/miniconda3/envs/AlphaFold

mkdir cif_pdbs
for pdb_id in $(cat $PDB_LIST);
do
    pdb_id=$(echo $pdb_id | awk '{print tolower($0)}')
    wget -O cif_pdbs/$pdb_id.cif https://files.rcsb.org/download/$pdb_id.cif
done

python /shared/work/NBD_Utilities/AlphaFold/hh-suite/scripts/cif2fasta.py -i cif_pdbs -o $pdb_id.fasta

/shared/work/NBD_Utilities/AlphaFold/bin/ffindex_from_fasta -s $STATE_fas.ff{data,index} $pdb_id.fasta

mpirun -np 8 \
  hhblits_mpi -i $STATE_fas -d <path_to/uniclust30> -oa3m $STATE_a3m_wo_ss -n 2 -cpu 1 -v 0

OMP_NUM_THREADS=1 mpirun -np 8 ffindex_apply_mpi $STATE_msa.ff{data,index} \
  -i $STATE_a3m_wo_ss.ffindex -d $STATE_a3m_wo_ss.ffdata \
    -- hhconsensus -M 50 -maxres 65535 -i stdin -oa3m stdout -v 0
rm $STATE_msa.ff{data,index}
