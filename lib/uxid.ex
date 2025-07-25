defmodule UXID do
  @moduledoc """
  Generates UXIDs and acts as an Ecto ParameterizedType

  **U**ser e**X**perience focused **ID**entifiers (UXIDs) are identifiers which:

  * Describe the resource (aid in debugging and investigation)
  * Work well with copy and paste (double clicking selects the entire ID)
  * Can be shortened for low cardinality resources
  * Are secure against enumeration attacks
  * Can be generated by application code (not tied to the datastore)
  * Are K-sortable (lexicographically sortable by time - works well with datastore indexing)
  * Do not require any coordination (human or automated) at startup, or generation
  * Are very unlikely to collide (more likely with less randomness)
  * Are easily and accurately transmitted to another human using a telephone

  Many of the concepts of Stripe IDs have been used in this library.
  """

  defstruct [
    :case,
    :delimiter,
    :encoded,
    :prefix,
    :rand_size,
    :rand,
    :rand_encoded,
    :size,
    :string,
    :time,
    :time_encoded
  ]

  @typedoc "Options for generating a UXID"
  @type option ::
          {:case, atom()} |
          {:time, integer()} |
          {:size, atom()} |
          {:rand_size, integer()} |
          {:prefix, String.t()} |
          {:delimiter, String.t()}

  @type options :: [option()]

  @typedoc "A UXID represented as a String"
  @type uxid_string :: String.t()

  @typedoc "An error string returned by the library if generation fails"
  @type error_string :: String.t()

  @typedoc "A UXID struct"
  @type t() :: %__MODULE__{
          case: atom() | nil,
          encoded: String.t() | nil,
          prefix: String.t() | nil,
          delimiter: String.t() | nil,
          rand_size: pos_integer() | nil,
          rand: binary() | nil,
          rand_encoded: String.t() | nil,
          size: atom() | nil,
          string: String.t() | nil,
          time: pos_integer() | nil,
          time_encoded: String.t() | nil
        }

  alias UXID.Encoder

  @default_delimiter "_"

  @spec generate(opts :: options()) :: {:ok, uxid_string()} | {:error, error_string()}
  @doc """
  Returns an encoded UXID string along with response status.
  """
  def generate(opts \\ []) do
    case new(opts) do
      {:ok, %__MODULE__{string: string}} ->
        {:ok, string}

      _other ->
        {:error, "Unknown error"}
    end
  end

  @spec generate!(opts :: options()) :: uxid_string()
  @doc """
  Returns an unwrapped encoded UXID string or raises on error.
  """
  def generate!(opts \\ []) do
    case generate(opts) do
      {:ok, uxid} -> uxid
      {:error, error} -> raise error
    end
  end

  @spec new(opts :: options()) :: {:ok, __MODULE__.t()} | {:error, error_string()}
  @doc """
  Returns a new UXID struct. This is useful for development.
  """
  def new(opts \\ []) do
    case = Keyword.get(opts, :case, encode_case())
    prefix = Keyword.get(opts, :prefix)
    rand_size = Keyword.get(opts, :rand_size)
    size = Keyword.get(opts, :size)
    delimiter = Keyword.get(opts, :delimiter, @default_delimiter)
    timestamp = Keyword.get(opts, :time, System.system_time(:millisecond))

    %__MODULE__{
      case: case,
      prefix: prefix,
      rand_size: rand_size,
      size: size,
      time: timestamp,
      delimiter: delimiter
    }
    |> Encoder.process()
  end

  def encode_case(), do: Application.get_env(:uxid, :case, :lower)

  # Define additional functions for custom Ecto type if Ecto is loaded
  if Code.ensure_loaded?(Ecto) do
    use Ecto.ParameterizedType

    @impl Ecto.ParameterizedType
    @doc """
    Generates a loaded version of the UXID.
    """
    def autogenerate(opts) do
      case = Map.get(opts, :case, encode_case())
      prefix = Map.get(opts, :prefix)
      size = Map.get(opts, :size)
      rand_size = Map.get(opts, :rand_size)

      __MODULE__.generate!(case: case, prefix: prefix, size: size, rand_size: rand_size)
    end

    @impl Ecto.ParameterizedType
    @doc """
    Returns the underlying schema type for a UXID.
    """
    def type(_opts), do: :string

    @impl Ecto.ParameterizedType
    @doc """
    Converts the options specified in the field macro into parameters to be used in other callbacks.
    """
    def init(opts) do
      # validate_opts(opts)
      Enum.into(opts, %{})
    end

    @impl Ecto.ParameterizedType
    @doc """
    Casts the given input to the UXID ParameterizedType with the given parameters.
    """
    def cast(data, _params), do: {:ok, data}

    @impl Ecto.ParameterizedType
    @doc """
    Loads the given term into a UXID.
    """
    def load(data, _loader, _params), do: {:ok, data}

    @impl Ecto.ParameterizedType
    @doc """
    Dumps the given term into an Ecto native type.
    """
    def dump(data, _dumper, _params), do: {:ok, data}
  end
end
