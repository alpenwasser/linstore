package Ltt::Plotting;
use strict;
use warnings;
use 5.10.0;
use Exporter;
use List::Util qw(sum max);
use Data::Dumper;
use File::Spec;
use GD::Graph::pie;
use GD::Graph::hbars;
use GD::Graph::bars;

use Ltt::Strings;
use Ltt::Statistics;
use Ltt::Imaging;

our @ISA= qw( Exporter );

# These CAN be exported.
our @EXPORT_OK = qw(
	print_hdd_size_plots
	print_hdd_vendor_plots
	print_ranking_list_plot
	print_groupings_plots
	print_os_plots
	);

# These are exported by default.
our @EXPORT = qw(
	print_hdd_size_plots
	print_hdd_vendor_plots
	print_ranking_list_plot
	print_groupings_plots
	print_os_plots
	);


sub _prepare_hdd_count_by_size_plot
{
	my $constants_ref		= shift;
	my $hdd_counts_by_size_ref	= shift;


	my $total_count = sum(values %{ $hdd_counts_by_size_ref });


	# $others_count: Aggregate   the  categories   which
	# would result into  uncomfortably narrow pie slices
	# into one slice labeled "others".
	my $others_count;


	my %prepared_data = map
	{
		if ($hdd_counts_by_size_ref->{$_} / $total_count
			>= $constants_ref->{pie_chart_percentage_threshold})
		{
			$_
			=>
			trim($hdd_counts_by_size_ref->{$_})
		}
		else
		{
			$others_count	+= $hdd_counts_by_size_ref->{$_};
			"others"
			=>
			$others_count
		}
	} keys %{ $hdd_counts_by_size_ref };

	my @labels = map
	{
		$_
		.(($_ ne "others" )?$constants_ref->{capacity_unit}:"" )
		. $constants_ref->{newline}
		. format_percentage($prepared_data{$_}/$total_count)."%"
		. $constants_ref->{newline}
		. $prepared_data{$_}
		. " drives"
	} keys %prepared_data;


	my @values = map { $_ } values %prepared_data;


	return (\@labels,\@values,$total_count);
}


sub _prepare_hdd_cap_by_size_plot
{
	my $constants_ref		= shift;
	my $hdd_comb_cap_by_size_ref	= shift;


	my $total_cap = sum(values %{ $hdd_comb_cap_by_size_ref });


	# $others_cap: Aggregate the  categories which would
	# result into  uncomfortably narrow pie  slices into
	# one slice labeled "others".
	my $others_cap;


	my %prepared_data = map
	{
		if ($hdd_comb_cap_by_size_ref->{$_} / $total_cap
			>= $constants_ref->{pie_chart_percentage_threshold})
		{
			$_
			=>
			trim($hdd_comb_cap_by_size_ref->{$_})
		}
		else
		{
			$others_cap += $hdd_comb_cap_by_size_ref->{$_};
			"others"
			=>
			$others_cap
		}
	} keys %{ $hdd_comb_cap_by_size_ref };


	my @labels = map
	{
		$_
		.(($_ ne "others")?$constants_ref->{capacity_unit}:"")
		. $constants_ref->{newline}
		. format_percentage($prepared_data{$_}/$total_cap)."%"
		. $constants_ref->{newline}
		. $prepared_data{$_}
		. $constants_ref->{capacity_unit}
	} keys %prepared_data;


	my @values = map { $_ } values %prepared_data;


	return (\@labels,\@values,$total_cap);
}


sub _prepare_hdd_count_by_vendor_plot
{
	my $constants_ref		= shift;
	my $hdd_counts_by_vendor_ref	= shift;

	my $total_count = sum(values %{ $hdd_counts_by_vendor_ref });

	# $others_count: Aggregate   the  categories   which
	# would result into  uncomfortably narrow pie slices
	# into one slice labeled "others".
	my $others_count;

	my %prepared_data = map
	{
		# Make	 sure	drives	from   "unspecified"
		# category   are  put	into  the   "others"
		# category.
		if ($_ eq "unspecified")
		{
			$others_count += trim(
				$hdd_counts_by_vendor_ref->{$_}
			);
			"others" => $others_count
		}
		# For all  other drive	vendors, we  apply a
		# minimum slize size.
		elsif ($hdd_counts_by_vendor_ref->{$_} / $total_count
			>= $constants_ref->{pie_chart_percentage_threshold})
		{
			trim($_) => trim($hdd_counts_by_vendor_ref->{$_})
		}
		elsif ($_ eq "unspecified")
		{
			$others_count
				+= trim($hdd_counts_by_vendor_ref->{$_});
			"others" => $others_count
		}
		else
		{
			$others_count += $hdd_counts_by_vendor_ref->{$_};
			"others" => $others_count
		}
	} keys %{ $hdd_counts_by_vendor_ref };


	my @labels = map
	{
		$_
		. $constants_ref->{newline}
		. format_percentage($prepared_data{$_}/$total_count)."%"
		. $constants_ref->{newline}
		. $prepared_data{$_}
		. " drives"
	} keys %prepared_data;


	my @values = map { $_ } values %prepared_data;


	return (\@labels,\@values,$total_count);
}


sub _prepare_hdd_cap_by_vendor_plot
{
	my $constants_ref		= shift;
	my $hdd_comb_cap_by_vendor_ref	= shift;


	my $total_cap = sum(values %{ $hdd_comb_cap_by_vendor_ref });

	# $others_cap: Aggregate the  categories which would
	# result into  uncomfortably narrow pie  slices into
	# one slice labeled "others".
	my $others_cap;

	my %prepared_data = map
	{
		if ($hdd_comb_cap_by_vendor_ref->{$_} / $total_cap
			>= $constants_ref->{pie_chart_percentage_threshold})
		{
			trim($_)
			=>
			trim($hdd_comb_cap_by_vendor_ref->{$_})
		}
		else
		{
			$others_cap += $hdd_comb_cap_by_vendor_ref->{$_};
			"others" => $others_cap
		}
	} keys %{ $hdd_comb_cap_by_vendor_ref };


	my @labels = map
	{
		$_
		. $constants_ref->{newline}
		. format_percentage($prepared_data{$_}/$total_cap)."%"
		. $constants_ref->{newline}
		. $prepared_data{$_}
		. $constants_ref->{capacity_unit}
	} keys %prepared_data;


	my @values = map { $_ } values %prepared_data;


	return (\@labels,\@values,$total_cap);
}


sub print_hdd_size_plots
{
	my $constants_ref		= shift;
	my $hdd_counts_by_size_ref	= shift;
	my $hdd_comb_cap_by_size_ref	= shift;


	my @data_count_by_size
		= _prepare_hdd_count_by_size_plot(
			$constants_ref,
			$hdd_counts_by_size_ref
		);


	my @data_cap_by_size
		= _prepare_hdd_cap_by_size_plot(
			$constants_ref,
			$hdd_comb_cap_by_size_ref
		);


	my $total_hdd_count	= pop @data_count_by_size;
	my $total_hdd_cap	= pop @data_cap_by_size;


	my $hdd_count_by_size_graph = GD::Graph::pie->new(800, 600);
	my $hdd_cap_by_size_graph = GD::Graph::pie->new(800, 600);

	my %pie_chart_hdd_count_by_size_configs
		= %{ $constants_ref->{pie_chart_configs} };
	my %pie_chart_hdd_cap_by_size_configs
		= %{ $constants_ref->{pie_chart_configs} };

	$pie_chart_hdd_count_by_size_configs{"logo"}
		= File::Spec->catfile(
			$constants_ref->{img_dir},
			$constants_ref->{logo_img}
		);
	$pie_chart_hdd_cap_by_size_configs{"logo"}
		= File::Spec->catfile(
			$constants_ref->{img_dir},
			$constants_ref->{logo_img}
		);

	$pie_chart_hdd_count_by_size_configs{"title"}
		= $constants_ref->{"pie_chart_hdd_count_by_size_title"};
	$pie_chart_hdd_cap_by_size_configs{"title"}
		= $constants_ref->{"pie_chart_hdd_cap_by_size_title"};


	$pie_chart_hdd_count_by_size_configs{"label"}
		= $constants_ref->{newline}
		. $constants_ref->{pie_chart_total_hdd_count_label}
		. $total_hdd_count
		. " drives";
	$pie_chart_hdd_cap_by_size_configs{"label"}
		= $constants_ref->{newline}
		. $constants_ref->{pie_chart_total_hdd_cap_label}
		. $constants_ref->{total_combined_capacity}
		. $constants_ref->{capacity_unit};

	$hdd_count_by_size_graph->set(%pie_chart_hdd_count_by_size_configs)
		or die $hdd_count_by_size_graph->error;
	$hdd_cap_by_size_graph->set(%pie_chart_hdd_cap_by_size_configs)
		or die $hdd_cap_by_size_graph->error;


	$hdd_count_by_size_graph->set_title_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{pie_chart_title_size});
	$hdd_count_by_size_graph->set_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{pie_chart_label_size});
	$hdd_count_by_size_graph->set_value_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{pie_chart_value_size});

	$hdd_cap_by_size_graph->set_title_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{pie_chart_title_size});
	$hdd_cap_by_size_graph->set_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{pie_chart_label_size});
	$hdd_cap_by_size_graph->set_value_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{pie_chart_value_size});

	my $gd_count_by_size
		= $hdd_count_by_size_graph->plot(\@data_count_by_size)
		or die $hdd_count_by_size_graph->error;
	my $gd_cap_by_size
		= $hdd_cap_by_size_graph->plot(\@data_cap_by_size)
		or die $hdd_cap_by_size_graph->error;


	# Watermark images with system configuration hash.
	my $gd_count_by_size_png
		= timestamp_img(
			$gd_count_by_size->png,
			substr($constants_ref->{timestamp}, 0, -2),
			$constants_ref->{systems_digest}
		);

	my $gd_cap_by_size_png
		= timestamp_img(
			$gd_cap_by_size->png,
			substr($constants_ref->{timestamp}, 0, -2),
			$constants_ref->{systems_digest}
		);


	# Write to files:
	open(IMG_COUNT, ">"
		. File::Spec->catfile(
			$constants_ref->{img_dir},
			$constants_ref->{timestamp}
			. $constants_ref->{hdd_count_by_size_img}
		)
	)
	or die $!;
	binmode IMG_COUNT;
	print IMG_COUNT $gd_count_by_size_png;
	close IMG_COUNT;

	open(IMG_CAP, ">"
		. File::Spec->catfile(
			$constants_ref->{img_dir},
			$constants_ref->{timestamp}
			. $constants_ref->{hdd_cap_by_size_img}
		)
	)
	or die $!;
	binmode IMG_CAP;
	print IMG_CAP $gd_cap_by_size_png;
	close IMG_CAP;
}


sub print_hdd_vendor_plots
{
	my $constants_ref		= shift;
	my $hdd_counts_by_vendor_ref	= shift;
	my $hdd_comb_cap_by_vendor_ref	= shift;


	my @data_count_by_vendor
		= _prepare_hdd_count_by_vendor_plot(
			$constants_ref,
			$hdd_counts_by_vendor_ref
		);

	my @data_cap_by_vendor
		= _prepare_hdd_cap_by_vendor_plot(
			$constants_ref,
			$hdd_comb_cap_by_vendor_ref
		);


	my $total_hdd_count	= pop @data_count_by_vendor;
	my $total_hdd_cap	= pop @data_cap_by_vendor;


	my $hdd_count_by_vendor_graph = GD::Graph::pie->new(800, 600);
	my $hdd_cap_by_vendor_graph = GD::Graph::pie->new(800, 600);

	my %pie_chart_hdd_count_by_vendor_configs
		= %{ $constants_ref->{pie_chart_configs} };
	my %pie_chart_hdd_cap_by_vendor_configs
		= %{ $constants_ref->{pie_chart_configs} };

	$pie_chart_hdd_count_by_vendor_configs{"logo"}
		= File::Spec->catfile(
			$constants_ref->{img_dir},
			$constants_ref->{logo_img}
		);
	$pie_chart_hdd_cap_by_vendor_configs{"logo"}
		= File::Spec->catfile(
			$constants_ref->{img_dir},
			$constants_ref->{logo_img}
		);

	$pie_chart_hdd_count_by_vendor_configs{"title"}
		= $constants_ref->{"pie_chart_hdd_count_by_vendor_title"};
	$pie_chart_hdd_cap_by_vendor_configs{"title"}
		= $constants_ref->{"pie_chart_hdd_cap_by_vendor_title"};


	$pie_chart_hdd_count_by_vendor_configs{"label"}
		= $constants_ref->{newline}
		. $constants_ref->{pie_chart_total_hdd_count_label}
		. $total_hdd_count
		. " drives";
	$pie_chart_hdd_cap_by_vendor_configs{"label"}
		= $constants_ref->{newline}
		. $constants_ref->{pie_chart_total_hdd_cap_label}
		. $constants_ref->{total_combined_capacity}
		. $constants_ref->{capacity_unit};

	$hdd_count_by_vendor_graph->set(%pie_chart_hdd_count_by_vendor_configs)
		or die $hdd_count_by_vendor_graph->error;
	$hdd_cap_by_vendor_graph->set(%pie_chart_hdd_cap_by_vendor_configs)
		or die $hdd_cap_by_vendor_graph->error;


	$hdd_count_by_vendor_graph->set_title_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{pie_chart_title_size});
	$hdd_count_by_vendor_graph->set_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{pie_chart_label_size});
	$hdd_count_by_vendor_graph->set_value_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{pie_chart_value_size});

	$hdd_cap_by_vendor_graph->set_title_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{pie_chart_title_size});
	$hdd_cap_by_vendor_graph->set_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{pie_chart_label_size});
	$hdd_cap_by_vendor_graph->set_value_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{pie_chart_value_size});

	my $gd_count_by_vendor
		= $hdd_count_by_vendor_graph->plot(\@data_count_by_vendor)
		or die $hdd_count_by_vendor_graph->error;
	my $gd_cap_by_vendor
		= $hdd_cap_by_vendor_graph->plot(\@data_cap_by_vendor)
		or die $hdd_cap_by_vendor_graph->error;


	# Watermark images with system configuration hash.
	my $gd_count_by_vendor_png
		= timestamp_img(
			$gd_count_by_vendor->png,
			substr($constants_ref->{timestamp}, 0, -2),
			$constants_ref->{systems_digest}
		);

	my $gd_cap_by_vendor_png
		= timestamp_img(
			$gd_cap_by_vendor->png,
			substr($constants_ref->{timestamp}, 0, -2),
			$constants_ref->{systems_digest}
		);


	# Write to files.
	open(IMG_COUNT, ">"
		. File::Spec->catfile(
			$constants_ref->{img_dir},
			$constants_ref->{timestamp}
			. $constants_ref->{hdd_count_by_vendor_img}
		)
	)
	or die $!;
	binmode IMG_COUNT;
	print IMG_COUNT $gd_count_by_vendor_png;
	close IMG_COUNT;

	open(IMG_CAP, ">"
		. File::Spec->catfile(
			$constants_ref->{img_dir},
			$constants_ref->{timestamp}
			. $constants_ref->{hdd_cap_by_vendor_img}
		)
	)
	or die $!;
	binmode IMG_CAP;
	print IMG_CAP $gd_cap_by_vendor_png;
	close IMG_CAP;
}


sub print_ranking_list_plot
{
	my $systems_ref		= shift;
	my $constants_ref	= shift;

	my @system_data	= (
		[
			map { $systems_ref->{$_}{username} }
			sort
			{
				# Sort	 first	by   storage
				# capacity,	 then	  by
				# post	number. Systems with
				# identical  capacities will
				# be  ranked higher  if they
				# were posted earlier.

				$systems_ref->{$b}{system_capacity}
				<=>
				$systems_ref->{$a}{system_capacity}
				||
				$systems_ref->{$a}{post}
				<=>
				$systems_ref->{$b}{post}
			}
			grep { $systems_ref->{$_}{rank} ne "UNRANKED" }
			keys %{ $systems_ref }
		],
		[
			map { $systems_ref->{$_}{system_capacity} }
			sort
			{
				# Same thing here, naturally.

				$systems_ref->{$b}{system_capacity}
				<=>
				$systems_ref->{$a}{system_capacity}
				||
				$systems_ref->{$a}{post}
				<=>
				$systems_ref->{$b}{post}
			}
			grep { $systems_ref->{$_}{rank} ne "UNRANKED" }
			keys %{ $systems_ref }
		],
	);


	my $ranking_chart = GD::Graph::hbars->new(800, 2000);

	my %ranking_chart_configs
		= %{ $constants_ref->{hbar_graph_configs} };

	$ranking_chart_configs{"logo"}
		= File::Spec->catfile(
			$constants_ref->{img_dir},
			$constants_ref->{logo_img}
		);

	$ranking_chart_configs{y_number_format}
		= \&format_number;

	$ranking_chart_configs{y_max_value}
		= $constants_ref->{hbar_max_y_scaling_factor}
		* max(@{ $system_data[1] });


	$ranking_chart->set(%ranking_chart_configs)
		or die $ranking_chart->error;


	$ranking_chart->set_title_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{ranking_chart_title_size}
	);

	$ranking_chart->set_x_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{ranking_chart_text_size}
	);

	$ranking_chart->set_x_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{ranking_chart_label_size}
	);

	$ranking_chart->set_y_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{ranking_chart_label_size}
	);

	$ranking_chart->set_x_axis_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{ranking_chart_axis_size}
	);

	$ranking_chart->set_y_axis_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{ranking_chart_axis_size}
	);

	$ranking_chart->set_values_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{ranking_chart_axis_size}
	);

	my $gd_ranking_list
		= $ranking_chart->plot(\@system_data)
		or die $ranking_chart->error;


	# Watermark image with system configuration hash.
	my $gd_ranking_list_png
		= timestamp_img(
			$gd_ranking_list->png,
			substr($constants_ref->{timestamp}, 0, -2),
			$constants_ref->{systems_digest}
		);


	# Write to file.
	open(IMG, ">"
		. File::Spec->catfile(
			$constants_ref->{img_dir},
			$constants_ref->{timestamp}
			. $constants_ref->{ranking_chart_img}
		)
	)
	or die $!;
	binmode IMG;
	print IMG $gd_ranking_list_png;
	close IMG;
}


sub print_groupings_plots
{
	my $systems_ref		= shift;
	my $constants_ref	= shift;


	my @grouped_data_by_count = (
		[
			map { $_ }
			sort keys %{ $constants_ref->{capacity_groups} }
		],
		[
			map { $constants_ref->{capacity_groups}{$_} }
			sort keys %{ $constants_ref->{capacity_groups} }
		]
	);


	my @grouped_data_by_contrib
		= get_capacity_group_contributions(
			[
				map  { $systems_ref->{$_}{system_capacity} }
				grep { $systems_ref->{$_}{rank} ne "UNRANKED" }
				keys %{ $systems_ref }
			],
			$constants_ref->{capacity_groups_contrib},
			$constants_ref->{capacity_range}
		);



	my $grouped_plot_by_count	= GD::Graph::hbars->new(800, 600);
	my $grouped_plot_by_contrib	= GD::Graph::hbars->new(800, 600);


	my %grouped_plot_by_count_configs
		= %{ $constants_ref->{grouped_hbar_by_count_configs} };
	my %grouped_plot_by_contrib_configs
		= %{ $constants_ref->{grouped_hbar_by_contrib_configs} };

	$grouped_plot_by_count_configs{y_max_value}
		= $constants_ref->{hbar_max_y_scaling_factor}
			* max(@{ $grouped_data_by_count[1] });
	$grouped_plot_by_contrib_configs{y_max_value}
		= $constants_ref->{hbar_max_y_scaling_factor}
			* max(@{ $grouped_data_by_contrib[1] });


	$grouped_plot_by_count_configs{logo}
		= File::Spec->catfile(
			$constants_ref->{img_dir},
			$constants_ref->{logo_img}
		);
	$grouped_plot_by_contrib_configs{logo}
		= File::Spec->catfile(
			$constants_ref->{img_dir},
			$constants_ref->{logo_img}
		);


	# Format capacities for values and axes:
	$grouped_plot_by_contrib_configs{y_number_format}
		= \&format_number;
	$grouped_plot_by_contrib_configs{values_format}
		= \&format_hbar_cap_value;


	$grouped_plot_by_count->set_title_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_title_size});

	$grouped_plot_by_count->set_x_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_text_size});

	$grouped_plot_by_count->set_x_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_label_size});

	$grouped_plot_by_count->set_y_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_label_size});

	$grouped_plot_by_count->set_x_axis_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_axis_size});

	$grouped_plot_by_count->set_y_axis_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_y_axis_size});

	$grouped_plot_by_count->set_values_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_axis_size});


	$grouped_plot_by_contrib->set_title_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_title_size});

	$grouped_plot_by_contrib->set_x_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_text_size});

	$grouped_plot_by_contrib->set_x_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_label_size});

	$grouped_plot_by_contrib->set_y_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_label_size});

	$grouped_plot_by_contrib->set_x_axis_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_axis_size});

	$grouped_plot_by_contrib->set_y_axis_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_y_axis_size});

	$grouped_plot_by_contrib->set_values_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_axis_size});


	$grouped_plot_by_count->set(%grouped_plot_by_count_configs)
		or die $grouped_plot_by_count->error;
	$grouped_plot_by_contrib->set(%grouped_plot_by_contrib_configs)
		or die $grouped_plot_by_contrib->error;


	my $gd_grouped_plot_by_count
		= $grouped_plot_by_count->plot(\@grouped_data_by_count)
		or die $grouped_plot_by_count->error;
	my $gd_grouped_plot_by_contrib
		= $grouped_plot_by_contrib->plot(\@grouped_data_by_contrib)
		or die $grouped_plot_by_contrib->error;


	# Watermark images with system configuration hash.
	my $gd_grouped_plot_by_count_png
		= timestamp_img(
			$gd_grouped_plot_by_count->png,
			substr($constants_ref->{timestamp}, 0, -2),
			$constants_ref->{systems_digest}
		);

	my $gd_grouped_plot_by_contrib_png
		= timestamp_img(
			$gd_grouped_plot_by_contrib->png,
			substr($constants_ref->{timestamp}, 0, -2),
			$constants_ref->{systems_digest}
		);


	# Write to files.
	open(IMG, ">"
		. File::Spec->catfile(
			$constants_ref->{img_dir},
			$constants_ref->{timestamp}
			.$constants_ref->{grouped_plot_by_count_img}
		)
	)
	or die $!;
	binmode IMG;
	print IMG $gd_grouped_plot_by_count_png;
	close IMG;

	open(IMG, ">"
		. File::Spec->catfile(
			$constants_ref->{img_dir},
			$constants_ref->{timestamp}
			. $constants_ref->{grouped_plot_by_contrib_img}
		)
	)
	or die $!;
	binmode IMG;
	print IMG $gd_grouped_plot_by_contrib_png;
	close IMG;
}


sub print_os_plots
{
	my $constants_ref	= shift;

        # For the statistics, we need
	# $constants_ref->{os_stats}
	# and
        # $constants_ref->{os_family_stats},
        # which are of the following structures:
	#
	# os_stats:
	# {
	#	OS abbreviation => {
	#			"os_name" => full OS name
	#			"count" => number of occurr.
	#			"percentage" => percentage,
	#			"family" => OS family
	#	}
	#}
	# os_family_stats:
	# {
	#	OS family => {
	#			"count" => number of occurr.
	#			"percentage" => percentage,
	#	}
	#}

	my @os_family_stats = (
		[
			map { trim($_) }
			sort {
				$constants_ref->{os_family_stats}{$b}{count}
				<=>
				$constants_ref->{os_family_stats}{$a}{count}
			} keys %{ $constants_ref->{os_family_stats} }
		],
		[
			map { trim($constants_ref->{os_family_stats}{$_}{count}) }
			sort {
				$constants_ref->{os_family_stats}{$b}{count}
				<=>
				$constants_ref->{os_family_stats}{$a}{count}
			}keys %{ $constants_ref->{os_family_stats} }
		]
	);


	my @os_stats = (
		[
			map { trim($_) }
			sort {
				$constants_ref->{os_stats}{$b}{count}
				<=>
				$constants_ref->{os_stats}{$a}{count}
			} keys %{ $constants_ref->{os_stats} }
		],
		[
			map { trim($constants_ref->{os_stats}{$_}{count}) }
			sort {
				$constants_ref->{os_stats}{$b}{count}
				<=>
				$constants_ref->{os_stats}{$a}{count}
			} keys %{ $constants_ref->{os_stats} }
		]
	);



	my $os_family_stats_plot = GD::Graph::hbars->new(800, 600);
	my $os_stats_plot        = GD::Graph::hbars->new(800, 600);


	my %os_family_stats_plot_configs
		= %{ $constants_ref->{hbar_os_family_stats_configs} };
	my %os_stats_plot_configs
		= %{ $constants_ref->{hbar_os_stats_configs} };

	$os_family_stats_plot_configs{y_max_value}
		= $constants_ref->{hbar_max_y_scaling_factor}
			* max(@{ $os_family_stats[1] });
	$os_stats_plot_configs{y_max_value}
		= $constants_ref->{hbar_max_y_scaling_factor}
			* max(@{ $os_stats[1] });


	$os_family_stats_plot_configs{logo}
		= File::Spec->catfile(
			$constants_ref->{img_dir},
			$constants_ref->{logo_img}
		);
	$os_stats_plot_configs{logo}
		= File::Spec->catfile(
			$constants_ref->{img_dir},
			$constants_ref->{logo_img}
		);


	$os_family_stats_plot->set_title_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_title_size});

	$os_family_stats_plot->set_x_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_text_size});

	$os_family_stats_plot->set_x_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_label_size});

	$os_family_stats_plot->set_y_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_label_size});

	$os_family_stats_plot->set_x_axis_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_axis_size});

	$os_family_stats_plot->set_y_axis_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_y_axis_size});

	$os_family_stats_plot->set_values_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_axis_size});


	$os_stats_plot->set_title_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_title_size});

	$os_stats_plot->set_x_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_text_size});

	$os_stats_plot->set_x_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_label_size});

	$os_stats_plot->set_y_label_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_label_size});

	$os_stats_plot->set_x_axis_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_axis_size});

	$os_stats_plot->set_y_axis_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_y_axis_size});

	$os_stats_plot->set_values_font(
		File::Spec->catfile("fonts","FreeMono.ttf"),
		$constants_ref->{grouped_plot_axis_size});


	$os_family_stats_plot->set(%os_family_stats_plot_configs)
		or die $os_family_stats_plot->error;
	$os_stats_plot->set(%os_stats_plot_configs)
		or die $os_stats_plot->error;


	my $gd_os_family_stats_plot
		= $os_family_stats_plot->plot(\@os_family_stats)
		or die $os_family_stats_plot->error;
	my $gd_os_stats_plot
		= $os_stats_plot->plot(\@os_stats)
		or die $os_stats_plot->error;


	# Watermark images with system configuration hash.
	my $gd_os_family_stats_plot_png
		= timestamp_img(
			$gd_os_family_stats_plot->png,
			substr($constants_ref->{timestamp}, 0, -2),
			$constants_ref->{systems_digest}
		);

	my $gd_os_stats_plot_png
		= timestamp_img(
			$gd_os_stats_plot->png,
			substr($constants_ref->{timestamp}, 0, -2),
			$constants_ref->{systems_digest}
		);


	# Write to files.
	open(IMG, ">"
		. File::Spec->catfile(
			$constants_ref->{img_dir},
			$constants_ref->{timestamp}
			.$constants_ref->{os_family_stats_img}
		)
	)
	or die $!;
	binmode IMG;
	print IMG $gd_os_family_stats_plot_png;
	close IMG;

	open(IMG, ">"
		. File::Spec->catfile(
			$constants_ref->{img_dir},
			$constants_ref->{timestamp}
			. $constants_ref->{os_stats_img}
		)
	)
	or die $!;
	binmode IMG;
	print IMG $gd_os_stats_plot_png;
	close IMG;
}


1;
