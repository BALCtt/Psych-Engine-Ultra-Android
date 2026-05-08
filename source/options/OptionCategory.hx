package options;

class OptionCategory
{
	public var name:String;

	public var description:String;
	public var options:Array<Option> = [];
	public var isOpen:Bool = false;

	public function new(name:String, description:String = '')
	{
		this.name        = name;
		this.description = description;
	}

	public function addOption(option:Option):Option
	{
		options.push(option);
		return option;
	}
}
