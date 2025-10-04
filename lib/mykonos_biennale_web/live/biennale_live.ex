defmodule MykonosBiennaleWeb.BiennaleLive do
  use MykonosBiennaleWeb, :live_view
  alias MykonosBiennale.Content

  @impl true
  def mount(_params, _session, socket) do
    # Get the current/most recent biennale (2025)
    current_biennale = Content.get_biennale_by_year(2025) || create_default_biennale()
    events = Content.list_events_for_biennale(current_biennale.id)

    {:ok,
     socket
     |> assign(:page_title, "Mykonos Biennale #{current_biennale.year}")
     |> assign(:biennale, current_biennale)
     |> assign(:events, events)
     |> assign(:events_by_type, group_events_by_type(events))}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  defp create_default_biennale do
    {:ok, biennale} =
      Content.create_biennale(%{
        year: 2025,
        theme: "Anti-Mausoleum",
        statement:
          "An international arts festival exploring the boundaries between performance, installation, video art, and experimental cinema.",
        description:
          "The 2025 Mykonos Biennale presents a radical reimagining of contemporary art practice, challenging conventional exhibition formats and celebrating ephemeral, live, and experimental works.",
        start_date: ~D[2025-06-01],
        end_date: ~D[2025-09-30]
      })

    biennale
  end

  defp group_events_by_type(events) do
    Enum.group_by(events, & &1.type)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen bg-black text-white">
        <%!-- Hero Section --%>
        <div class="relative min-h-screen flex flex-col items-center justify-center px-6 py-20">
          <%!-- Dramatic Title --%>
          <div class="text-center space-y-8 max-w-4xl">
            <h1 class="text-6xl md:text-8xl lg:text-9xl font-bold tracking-tight uppercase">
              <span class="block text-white">Mykonos</span>
              <span class="block text-gray-400">Biennale</span>
            </h1>

            <p class="text-xl md:text-2xl text-gray-400 font-light tracking-wider uppercase">
              {@biennale.year} — {@biennale.theme}
            </p>

            <div class="pt-8">
              <p class="text-lg md:text-xl text-gray-300 leading-relaxed max-w-2xl mx-auto">
                {@biennale.statement}
              </p>
            </div>

            <%!-- CTA Buttons --%>
            <div class="flex flex-col sm:flex-row gap-4 justify-center pt-8">
              <.link
                navigate={~p"/program"}
                class="px-8 py-4 bg-white text-black font-bold uppercase tracking-wider hover:bg-gray-200 transition-colors"
              >
                View Program
              </.link>
              <.link
                navigate={~p"/archive"}
                class="px-8 py-4 border-2 border-white text-white font-bold uppercase tracking-wider hover:bg-white hover:text-black transition-colors"
              >
                Archive
              </.link>
            </div>
          </div>

          <%!-- Scroll Indicator --%>
          <div class="absolute bottom-8 left-1/2 transform -translate-x-1/2 animate-bounce">
            <svg class="w-6 h-6 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19 9l-7 7-7-7"
              >
              </path>
            </svg>
          </div>
        </div>

        <%!-- Program Preview Section --%>
        <div class="px-6 py-20 md:py-32 max-w-7xl mx-auto">
          <h2 class="text-4xl md:text-6xl font-bold uppercase mb-16 text-center">
            Program {@biennale.year}
          </h2>

          <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            <%!-- Exhibition Card --%>
            <.program_card
              number="01"
              title="Exhibitions"
              description="Contemporary installations across multiple venues in Mykonos"
              gradient="from-gray-800 to-black"
            />

            <%!-- Dramatic Nights Card --%>
            <.program_card
              number="02"
              title="Dramatic Nights"
              description="Live performances and experimental theater under the stars"
              gradient="from-purple-900/30 to-black"
            />

            <%!-- Video Graffiti Card --%>
            <.program_card
              number="03"
              title="Video Graffiti"
              description="Large-scale video projections transforming urban landscapes"
              gradient="from-blue-900/30 to-black"
            />

            <%!-- Short Films Card --%>
            <.program_card
              number="04"
              title="Short Films"
              description="International experimental and narrative short film screenings"
              gradient="from-red-900/30 to-black"
            />

            <%!-- Performances Card --%>
            <.program_card
              number="05"
              title="Performances"
              description="Multi-disciplinary live art and site-specific interventions"
              gradient="from-green-900/30 to-black"
            />

            <%!-- Workshops Card --%>
            <.program_card
              number="06"
              title="Workshops"
              description="Artist-led sessions exploring contemporary art practices"
              gradient="from-yellow-900/30 to-black"
            />
          </div>
        </div>

        <%!-- Archive Teaser Section --%>
        <div class="px-6 py-20 md:py-32 bg-gray-950">
          <div class="max-w-7xl mx-auto">
            <h2 class="text-4xl md:text-6xl font-bold uppercase mb-16 text-center">
              Archive
            </h2>

            <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
              <.link
                navigate={~p"/archive/2024"}
                class="aspect-square bg-black border border-gray-800 flex items-center justify-center hover:bg-gray-900 transition-colors"
              >
                <span class="text-3xl font-bold text-gray-600">2024</span>
              </.link>
              <.link
                navigate={~p"/archive/2022"}
                class="aspect-square bg-black border border-gray-800 flex items-center justify-center hover:bg-gray-900 transition-colors"
              >
                <span class="text-3xl font-bold text-gray-600">2022</span>
              </.link>
              <.link
                navigate={~p"/archive/2015"}
                class="aspect-square bg-black border border-gray-800 flex items-center justify-center hover:bg-gray-900 transition-colors"
              >
                <span class="text-3xl font-bold text-gray-600">2015</span>
              </.link>
              <.link
                navigate={~p"/archive/2013"}
                class="aspect-square bg-black border border-gray-800 flex items-center justify-center hover:bg-gray-900 transition-colors"
              >
                <span class="text-3xl font-bold text-gray-600">2013</span>
              </.link>
            </div>

            <div class="text-center mt-12">
              <.link
                navigate={~p"/archive"}
                class="px-8 py-4 border-2 border-white text-white font-bold uppercase tracking-wider hover:bg-white hover:text-black transition-colors inline-block"
              >
                View All Editions
              </.link>
            </div>
          </div>
        </div>

        <%!-- Footer --%>
        <div class="px-6 py-12 border-t border-gray-800">
          <div class="max-w-7xl mx-auto flex flex-col md:flex-row justify-between items-center gap-6">
            <div class="text-center md:text-left">
              <p class="text-sm text-gray-400 uppercase tracking-wider">
                Mykonos Biennale © {@biennale.year}
              </p>
            </div>

            <div class="flex gap-6">
              <.link
                navigate={~p"/about"}
                class="text-sm text-gray-400 hover:text-white uppercase tracking-wider"
              >
                About
              </.link>
              <a href="#" class="text-sm text-gray-400 hover:text-white uppercase tracking-wider">
                Contact
              </a>
              <a href="#" class="text-sm text-gray-400 hover:text-white uppercase tracking-wider">
                Press
              </a>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp program_card(assigns) do
    ~H"""
    <div class="group cursor-pointer">
      <div class="aspect-square bg-gray-900 mb-4 relative overflow-hidden">
        <div class={"absolute inset-0 bg-gradient-to-br #{@gradient} group-hover:scale-105 transition-transform duration-500"}>
        </div>
        <div class="absolute inset-0 flex items-center justify-center">
          <span class="text-6xl text-gray-600">{@number}</span>
        </div>
      </div>
      <h3 class="text-xl font-bold uppercase mb-2">{@title}</h3>
      <p class="text-gray-400 text-sm">
        {@description}
      </p>
    </div>
    """
  end
end
