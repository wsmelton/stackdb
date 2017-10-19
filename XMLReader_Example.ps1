$f = [System.Xml.XmlReader]::Create("C:\Temp\SE\Woodworking\woodworking.stackexchange.com\Tags.xml")
while ($f.Read()) {
	switch ($f.NodeType) {
		([System.Xml.XmlNodeType]::Element) {
			if ($f.Name -eq 'row') {
				foreach ($a in $f.AttributeCount) {
					http://diranieh.com/NETXML/XmlReader
					$f.GetAttribute($a)
				}
			}
		}
	}
	pause
}
