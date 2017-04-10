function tensor_struct = find_or_calculate_environment(obj, temperature, chi, N)
  % Checks if converged tensors are already in the database.
  % If tensors already exist, do nothing.
  % If tensors with same temperature and chi, but with lower N exist,
  % use those as a starting point and add the remaining amount of steps required.

  query = ['SELECT * ' ...
    'FROM tensors ' ...
    'WHERE temperature = ? AND chi = ? AND n <= ? AND initial = ? AND q = ? ' ...
    'ORDER BY n DESC ' ...
    'LIMIT 1'];
  if obj.LOAD_FROM_DB
    query_result = sqlite3.execute(obj.db_id, query, temperature, chi, N, obj.initial_condition, obj.q);
  else
    query_result = [];
  end

  if isempty(query_result)
    display('Did not find record');
    iterations_remaining = N;
    [initial_C, initial_T] = obj.initial_tensors(temperature);
    [C, T, convergence, truncation_error] = obj.calculate_environment(...
      temperature, chi, iterations_remaining, initial_C, initial_T);
  else
    iterations_remaining = N - query_result.n;
    % display(['Found record: ' num2str(iterations_remaining) ' iterations remaining.'])
    if iterations_remaining > 0
      [initial_C, initial_T] = Util.deserialize_tensors(query_result);
      [C, T, convergence, truncation_error] = obj.calculate_environment(temperature, chi, iterations_remaining, initial_C, initial_T);
    else
      % 0 iterations remaining, nothing to simulate!
      [C, T] = Util.deserialize_tensors(query_result);
      convergence = query_result.convergence;
      if isempty(query_result.truncation_error)
        display('Found empty truncation error. Updating...')
        % Do one additional iteration to recalculate truncation_error.
        [~, ~, ~, truncation_error] = obj.calculate_environment(...
          temperature, chi, 1, C, T);
        query = ['update tensors set truncation_error = ? ' ...
          'where temperature = ? AND chi = ? AND n = ? AND initial = ? AND q = ?'];
        sqlite3.execute(obj.db_id, query, truncation_error, temperature, ...
          chi, N, obj.initial_condition, obj.q);
      else
        truncation_error = query_result.truncation_error;
      end
    end
  end

  if iterations_remaining > 0
    obj.save_to_db(temperature, chi, N, convergence, C, T, truncation_error);
  end

  tensor_struct = struct('C', C, 'T', T, 'convergence', convergence, 'truncation_error', truncation_error);
end
