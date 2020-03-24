"use strict"
dataTable = do ->
	# TODO
	# {{{
	# }}}
	# helpers
	hereDoc = (f) -> # {{{
		f = f.toString!
		a = f.indexOf '/*'
		b = f.lastIndexOf '*/'
		return f.substring a + 2, b - 1 .trim!
	# }}}
	htmlToElement = do -> # {{{
		temp = document.createElement 'template'
		return (html) ->
			temp.innerHTML = html
			return temp.content.firstChild
	# }}}
	# templates
	svgPlus = hereDoc !-> # {{{
		/*
		<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
			<circle class="e1" cx="50" cy="50" r="49"/>
			<circle class="e2" cx="50" cy="50" r="46"/>
			<path class="e3" d="M64 17c0-1-1-2-2-2H38c-1 0-2 1-2 2v19H17c-1 0-2 1-2 2v24c0 1 1 2 2 2h19v19c0 1 1 2 2 2h24c1 0 2-1 2-2V64h19c1 0 2-1 2-2V38c0-1-1-2-2-2H64V17z"/>
			<path class="e4" d="M81 60H62c-1 0-2 1-2 2v19H40V62c0-1-1-2-2-2H19V40h19c1 0 2-1 2-2V19h20v19c0 1 1 2 2 2h19v20z"/>
		</svg>
		*/
	# }}}
	svgRemove = hereDoc !-> # {{{
		/*
		<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
			<circle style="stroke: black; fill: white;" cx="50" cy="50" r="49"/>
			<circle style="stroke:none; fill:white;" cx="50" cy="50" r="46"/>
			<path style="stroke:none; fill:red;" d="M36 16c-1-1-2-1-3 0L16 33c-1 1-1 2 0 3l14 14-14 14c-1 1-1 2 0 3l17 17c1 1 2 1 3 0l14-14 14 14c1 1 2 1 3 0l17-17c1-1 1-2 0-3L70 50l14-14c1-1 1-2 0-3L67 16c-1-1-2-1-3 0L50 30 36 16z"/>
			<path style="stroke:none; fill:none;" d="M79 35L65 49c-1 1-1 2 0 3l14 14-14 14-14-14c-1-1-2-1-3 0L34 80 20 66l14-14c1-1 1-2 0-3L20 35l14-14 14 14c1 1 2 1 3 0l14-14 14 14z"/>
		</svg>
		*/
	# }}}
	itemTemplate = hereDoc !-> # {{{
		/*
		<div class="item">
			<div class="preview">
				<div class="box"><img></div>
			</div>
			<div class="remover">
				<div class="box">{{x}}</div>
			</div>
		</div>
		*/
	# }}}
	uploadTemplate = hereDoc !-> # {{{
		/*
		<div class="upload">
			<div class="box">{{a}}</div>
		</div>
		*/
	# }}}
	# constructors
	# ...
	api = # {{{
		get: (data, k) -> # {{{
			# properties
			switch k
			| 'prop' =>
				return data[k]
			# methods
			#if data.api.hasOwnProperty k
			#	return data.api[k]
			# fail
			return null
		# }}}
		set: (data, k, v) -> # {{{
			# set dynamic properties
			switch k
			| 'prop' =>
				true
			# done
			return true
		# }}}
	# }}}
	# factory
	return (node, opts) ->
		return new Proxy (new Data node, opts), api



/***
<div class="w3ui dataTable">
  <div role="table" class="table">
    <div role="rowgroup" class="head">
      <div role="row">
        <div role="columnheader">
          <div>Дата</div>
        </div>
        <div role="columnheader">
          <div>№ пут.листа</div>
        </div>
        <div role="columnheader">
          <div>ФИО Водителя</div>
        </div>
        <div role="columnheader">
          <div>ТС</div>
        </div>
        <div role="columnheader">
          <div>Госномер</div>
        </div>
        <div role="columnheader">
          <div>Диспетчер</div>
        </div>
        <div role="columnheader">
          <div>Механик</div>
        </div>
      </div>
    </div>
    <div role="rowgroup" class="body">


<?php
$d = getJournalPl();
$c = count($d);
$i = -1;
while (++$i < $c) {
  $row = $d[$i];
?>
      <div role="row" data-id="<?php echo $row['plist_id']; ?>">
        <div role="cell"><div><?php echo $row['dat']; ?></div></div>
        <div role="cell"><div><?php echo $row['nom']; ?></div></div>
        <div role="cell"><div><?php echo $row['vodm']; ?></div></div>
        <div role="cell"><div><?php echo $row['autot'].' '.$row['autom']; ?></div></div>
        <div role="cell"><div><?php echo $row['gosnum']; ?></div></div>
        <div role="cell"><div><?php echo $row['staffdisp']; ?></div></div>
        <div role="cell"><div><?php echo $row['staffmeh']; ?></div></div>
      </div>
<?php
}
?>


    </div>
  </div>
</div>
/***/



