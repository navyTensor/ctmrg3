function data_collapse_chi_bounding_box
  chi_values = [8, 16, 32];
  tolerance = 1e-7;
  x_width_left = 500;
  x_width_right = 0.0;
  number_of_points = 5;
  throw_away_width = 1;

  % corr_lengths = find_corresponding_correlation_lengths(chi_values, tolerance)
  corr_lengths = zeros(1, numel(chi_values));
  for c = 1:numel(chi_values)
    corr_lengths(c) = ctm_length_scale(Constants.T_crit, chi_values(c), tolerance);
  end

  % skip first few chi_values
  % skipBegin = 0;
  % chi_values = chi_values(skipBegin + 1 : end)
  % corr_lengths = corr_lengths(skipBegin + 1 : end)
  % chi_values = chi_values([3 8 10])
  % corr_lengths = corr_lengths([3 8 10])

  temperatures = find_corresponding_temperatures(chi_values, corr_lengths, x_width_left, x_width_right, number_of_points, throw_away_width);
  order_parameters = find_corresponding_order_params(temperatures, chi_values, tolerance);


  [total_mse, mse_L_values] = data_collapse(chi_values, temperatures, order_parameters, corr_lengths, true)

  xlabel('$t\xi_{\max}(\chi)$')
  ylabel('$\xi_{\max}(\chi)^{\beta/\nu}m(t, \xi_{\max}(\chi))$')
  legend_labels = {};
  for c = 1:numel(chi_values)
    if c == numel(chi_values)
      legend_labels{end + 1} = ['$\chi = ' num2str(chi_values(c)) '$'];
    else
      legend_labels{end + 1} = ['$\chi = ' num2str(chi_values(c)) '$, mse = ' num2str(mse_L_values(c))];
    end
  end
  legend(legend_labels, 'Location', 'best')
  title(['tolerance = ' num2str(tolerance)])
  % make_legend(chi_values, '\chi')
end

function temperatures = find_corresponding_temperatures(chi_values, corr_lengths, x_width_left, x_width_right, number_of_points, throw_away_width)
  temperatures = containers.Map('keyType', 'double', 'valueType', 'any');

  for c = 1:numel(chi_values)
    temperatures_chi = find_temperatures(corr_lengths(c), x_width_left, x_width_right, number_of_points);
    temperatures_chi = throw_away_if_far_from_Tc(temperatures_chi, throw_away_width);
    temperatures(chi_values(c)) = temperatures_chi;
  end
end


function temperatures = find_temperatures(corr_length, x_width_left, x_width_right, number_of_points)
  reduced_temperatures = linspace(-x_width_left, x_width_right, number_of_points) ./ corr_length;
  temperatures = Constants.inverse_reduced_Ts(reduced_temperatures);
end

function corr_lengths = find_corresponding_correlation_lengths(chi_values, tolerance)
  corr_lengths = zeros(1, numel(chi_values));
  temperature = Constants.T_crit;
  sim = FixedToleranceSimulation(temperature, chi_values, tolerance).run();
  corr_lengths = sim.compute(CorrelationLengthAfun);
  % we round the correlation lengths we use to 5 decimal places. Otherwise, due to the varying answer of
  % the Lanczos algorithm, we have to compute observables at slightly different (1e-13)
  % temperatures each time.
  corr_lengths = round(corr_lengths, 5);
end
