function store_to_db(obj, T_pseudocrit, q, N, tensors, truncation_error)
  query = ['insert into t_pseudocrits (t_pseudocrit, q, n, c, t, truncation_error, chi, tol_x, initial) ' ...
    'values (?, ?, ?, ?, ?, ?, ?, ?, ?)'];
  [bytesC, bytesT] = Util.serialize_tensors(tensors.C, tensors.T);
  chi = size(tensors.C, 1);

  sqlite3.execute(obj.db_id, query, T_pseudocrit, q, N, bytesC, bytesT, truncation_error, chi, obj.TolX, ...
    obj.initial_condition);
end
